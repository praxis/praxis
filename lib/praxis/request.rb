module Praxis

  class Request
    attr_reader :env, :query
    attr_accessor :route_params, :action

    def initialize(env)
      @env = env
      @query = Rack::Utils.parse_nested_query(env['QUERY_STRING'.freeze])
      @route_params = {}
      @path_version_matcher = path_version_matcher
    end

    def content_type
      @env['CONTENT_TYPE'.freeze]
    end

    # The media type (type/subtype) portion of the CONTENT_TYPE header
    # without any media type parameters. e.g., when CONTENT_TYPE is
    # "text/plain;charset=utf-8", the media-type is "text/plain".
    #
    # For more information on the use of media types in HTTP, see:
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7
    def media_type
      content_type && content_type.split(/\s*[;,]\s*/, 2).first.downcase
    end

    def path
      @env['PATH_INFO'.freeze]
    end

    attr_accessor :headers, :params, :payload

    def params_hash
      return {} if params.nil?

      params.attributes.each_with_object({}) do |(k,v),hash|
        hash[k] = v
      end
    end

    def verb
      @env['REQUEST_METHOD'.freeze]
    end

    def raw_params
      @raw_params ||= begin
        params = query.merge(route_params)
        params.delete('api_version'.freeze)
        params
      end
    end

    def raw_payload
      @raw_payload ||= begin
        if (input = env['rack.input'.freeze].read)
          env['rack.input'.freeze].rewind
          input
        end
      end
    end

    def coalesce_inputs!
      self.raw_params
      self.raw_payload
    end
    
    def self.path_version_prefix
      "/v".freeze
    end
    
    def path_version_matcher
      %r{^#{Request.path_version_prefix}(?<version>[^\/]+)\/}.freeze
    end
    
    def version(using: [:header,:params].freeze)
      result = nil
      Array(using).find do |mode|
        case mode
        when :header ;
          result = env["HTTP_X_API_VERSION".freeze]
        when :params ;
          result = @query['api_version'.freeze]
        when :path ;
          m = self.path.match(@path_version_matcher) 
          result = m[:version] unless m.nil?
        else
          raise "Unknown method for retrieving the API version: #{mode}"
        end
      end
      return result || 'n/a'.freeze
    end

    def load_headers(context)
      return unless action.headers
      defined_headers = action.precomputed_header_keys_for_rack.each_with_object(Hash.new) do |(upper,original), hash|
        hash[original] = self.env[upper] if self.env.has_key? upper
      end
      self.headers = action.headers.load(defined_headers, context)
    end

    def load_params(context)
      return unless action.params
      self.params = action.params.load(self.raw_params, context)
    end

    def load_payload(context)
      return unless action.payload
      raw = case content_type
        when %r|^application/x-www-form-urlencoded|i
          Rack::Utils.parse_nested_query(self.raw_payload)
        when nil
          {}
        else
          self.raw_payload
        end

      self.payload = action.payload.load(raw, context, content_type: content_type)
    end

    def validate_headers(context)
      return [] unless action.headers

      action.headers.validate(self.headers, context)
    end

    def validate_params(context)
      return [] unless action.params

      action.params.validate(self.params, context)
    end

    def validate_payload(context)
      return [] unless action.payload

      action.payload.validate(self.payload, context)
    end

    # versions that matched all the conditions of the request (except its version)
    def unmatched_versions
      @unmatched_versions ||= Set.new
    end

  end

end
