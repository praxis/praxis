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
    end

#   def self.definition
#     ApiDefinition.instance.response(self.response_name)
#   end

    def initialize(status:200, headers:{}, body:'')
      @name    = response_name
      @status  = status
      @headers = headers
      @body    = body
      @form_data = nil
      @parts = Hash.new
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

    def finish
      case @body
      when Hash
        @body = JSON.pretty_generate(@body)
      end

      @body = Array(@body)

      if @form_data
        if @body.any?
          unless @body.last =~ /\n$/
            @body << "\r\n"
          end
        end

        @parts.each do |name, part|
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
      unless ( response_definition = action.responses[response_name] )
        raise ArgumentError, "Attempting to return a response with name #{response_name} " \
          "but no response definition with that name can be found"
      end

      response_definition.validate(self)
    end


  end
end
