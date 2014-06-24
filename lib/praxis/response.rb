
module Praxis
  class Response

    attr_accessor :name, :status, :headers, :body, :extra_data,
      :request

    class << self
      attr_accessor :response_name
    end

    def self.definition
      ApiDefinition.instance.response(self.response_name)
    end

    def definition
      self.class.definition
    end

    def response_name
      self.class.response_name
    end

    def initialize(status:200, headers:{}, body:'', **extra_data)
      @name = self.class.response_name
      @status = status
      @headers = headers
      @body = body
      @extra_data = extra_data
    end

    def to_rack
      case @body
      when Hash
        @body = JSON.pretty_generate(@body)
      end

      @body = Array(body)
      [@status, @headers, @body]
    end


    def validate(action)
      # Validate status code if defined in the spec
      if definition.status && self.status != definition.status
        raise "Invalid response code detected. Response #{definition.name} dictates status of #{definition.status} but this response is returning #{self.status}."
      end

      # Validate location
      if location = definition.location
        case location
        when Regexp
          raise "LOCATION does not match regexp #{location.inspect}!" unless location =~ self.headers['Location']
        when String
          raise "LOCATION does not match string #{location}!" unless location == self.headers['Location']
        else
          raise "Unknown location spec"
        end
      end

      # Validate headers
      if hdrs = definition.headers
        hdrs = [ hdrs ] if !hdrs.is_a?(Array)

        hdrs.each do |h|
          valid = false

          if h.is_a?(Hash)
            valid = h.all? do |k, v|
              self.headers.has_key?(k) && self.headers[k] == v
            end
          elsif h.is_a?(String)
            valid = self.headers.has_key?(h)
          elsif h.is_a?(Symbol)
            raise "Symbols are not supported"
          end

          raise "headers missing" if !valid
        end
      end

      conf_class = action.controller_config

      extracted_identifier = self.headers['Content-Type']
      # Support "+json" and options like ";type=collection"
      extracted_identifier = extracted_identifier && extracted_identifier.split('+').first.split(';').first

      if definition.media_type == :controller_defined
        conf_class.media_type === extracted_identifier
      end

      if (mt = definition.media_type)
        if mt == :controller_defined
          mt = conf_class.media_type
          raise "Error validating content type: this controller (#{conf_class}) doesn't have any associated media_type" unless mt
        end

        unless mt === extracted_identifier
          raise "Bad Content-Type: returned type #{extracted_identifier} does not match type #{mt.identifier} as described in response: #{definition.name}"
        end
      end

    end

  end
end
