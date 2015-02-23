module Praxis

  class Request
    attr_reader :env, :query
    attr_accessor :route_params, :action

    PATH_VERSION_PREFIX = "/v".freeze
    PATH_VERSION_MATCHER = %r{^#{PATH_VERSION_PREFIX}(?<version>[^\/]+)\/}.freeze
    CONTENT_TYPE_NAME = 'CONTENT_TYPE'.freeze
    PATH_INFO_NAME = 'PATH_INFO'.freeze
    REQUEST_METHOD_NAME = 'REQUEST_METHOD'.freeze
    QUERY_STRING_NAME = 'QUERY_STRING'.freeze
    API_VERSION_HEADER_NAME = "HTTP_X_API_VERSION".freeze
    API_VERSION_PARAM_NAME = 'api_version'.freeze
    API_NO_VERSION_NAME = 'n/a'.freeze
    VERSION_USING_DEFAULTS = [:header,:params].freeze
    
    def initialize(env)
      @env = env
      @query = Rack::Utils.parse_nested_query(env[QUERY_STRING_NAME])
      @route_params = {}
      @path_version_matcher = path_version_matcher
    end

    def content_type
      @env[CONTENT_TYPE_NAME]
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
      @env[PATH_INFO_NAME]
    end

    attr_accessor :headers, :params, :payload

    def params_hash
      return {} if params.nil?

      params.attributes.each_with_object({}) do |(k,v),hash|
        hash[k] = v
      end
    end

    def verb
      @env[REQUEST_METHOD_NAME]
    end

    def raw_params
      @raw_params ||= begin
        params = query.merge(route_params)
        params.delete(API_VERSION_PARAM_NAME)
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
      PATH_VERSION_PREFIX
    end
    
    def path_version_matcher
      PATH_VERSION_MATCHER
    end
    
    def version(using: VERSION_USING_DEFAULTS )
      result = nil
      Array(using).find do |mode|
        case mode
        when :header ;
          result = env[API_VERSION_HEADER_NAME]
        when :params ;
          result = @query[API_VERSION_PARAM_NAME]
        when :path ;
          m = self.path.match(@path_version_matcher) 
          result = m[:version] unless m.nil?
        else
          raise "Unknown method for retrieving the API version: #{mode}"
        end
      end
      return result || API_NO_VERSION_NAME
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
