module Praxis

  class Request
    attr_reader :env, :query, :version
    attr_accessor :route_params, :action

    def initialize(env)
      @env = env
      @query = Rack::Utils.parse_nested_query(env['QUERY_STRING'.freeze])
      @route_params = {}
      load_version
    end
    
    def path 
      @env['PATH_INFO'.freeze]
    end

    attr_accessor :headers, :params, :payload

    def params_hash
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
          # FIXME: handle non-url-form-encoded inputs
          Rack::Utils.parse_nested_query(input)
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
      self.params = action.params.load(self.raw_params, context)
    end

    def load_payload(context)
      self.payload = action.payload.load(self.raw_payload, context)
    end

    def validate_headers(context)
      return unless self.headers
      errors = self.headers.validate(context)
      raise "nope: #{errors.inspect}" if errors.any?
    end


    def validate_params(context)
      errors = self.params.validate(context)
      raise "nope: #{errors.inspect}" if errors.any?
    end


    def validate_payload(context)
      errors = self.payload.validate(context)
      raise "nope: #{errors.inspect}" if errors.any?
    end


  end

end
