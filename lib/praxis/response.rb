module Praxis
  class Response


    attr_reader :name
    attr_reader :parts

    attr_accessor :status
    attr_accessor :headers
    attr_accessor :body
    attr_accessor :request

    class << self
      attr_accessor :response_name
      attr_accessor :status
    end

    def self.inherited(klass)
      klass.response_name = klass.name.demodulize.underscore.to_sym
      klass.status = self.status if self.status
    end

    def initialize(status:self.class.status, headers:{}, body:'')
      @name    = response_name
      @status  = status
      @headers = headers
      @body    = body
      @form_data = nil
      @parts = Hash.new
    end

    def handle
    end

    def add_part(name=nil, part)
      @form_data ||= begin
        form = MIME::Multipart::FormData.new
        @headers.merge! form.headers.headers
        form
      end

      name ||= "part-#{part.object_id}"

      @parts[name.to_s] = part
    end

    def response_name
      self.class.response_name
    end

    def format!
    end

    def encode!
      case @body
      when Hash, Array
        @body = JSON.pretty_generate(@body)
      end
    end

    def finish
      format!
      encode!

      @body = Array(@body)

      if @form_data
        if @body.any?
          unless @body.last =~ /\n$/
            @body << "\r\n"
          end
        end

        @parts.each do |name, part|
          part.encode!
          entity = MIME::Text.new(part.body)

          part.headers.each do |header_name, header_value|
            entity.headers.set header_name, header_value
          end

          @form_data.add entity, name
        end

        @body << @form_data.body.to_s
      end

      [@status, @headers, @body]
    end


    # Validates the response
    #
    # @param [Object] action
    #
    def validate(action)
      return if response_name == :validation_error
      unless ( response_definition = action.responses[response_name] )
        raise ArgumentError, "Attempting to return a response with name #{response_name} " \
          "but no response definition with that name can be found"
      end

      response_definition.validate(self)
    end


  end
end
