module Praxis

  class Request
    attr_reader :env, :query, :version, :unmatched_versions
    attr_accessor :route_params, :action


    def initialize(env)
      @env = env
      @query = Rack::Utils.parse_nested_query(env['QUERY_STRING'.freeze])
      @route_params = {}
      load_version
      # versions that matched all the conditions of the request (except its version)
      @unmatched_versions = Set.new
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

    def load_version
      @version = env.fetch("HTTP_X_API_VERSION".freeze,
                           @query.fetch('api_version'.freeze, 'n/a'.freeze))
    end

    def load_headers(context)
      return unless action.headers
      defined_headers = action.headers.attributes.keys.each_with_object(Hash.new) do |name, hash|
        env_name = if name == :CONTENT_TYPE || name == :CONTENT_LENGTH
          name.to_s
        else
          "HTTP_#{name}"
        end
        hash[name] = self.env[env_name] if self.env.has_key? env_name
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


  end

end
