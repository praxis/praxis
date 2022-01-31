# frozen_string_literal: true

module Praxis
  class Response
    attr_reader :name, :parts

    attr_accessor :status, :headers, :body, :request

    class << self
      attr_accessor :response_name, :status
    end

    def self.inherited(klass)
      klass.response_name = klass.name.demodulize.underscore.to_sym
      klass.status = status if status
    end

    def initialize(status: self.class.status, headers: {}, body: nil, location: nil)
      @name    = response_name
      @status  = status
      @headers = headers
      @body    = body
      @headers['Location'] = location if location
      @form_data = nil
      @parts = {}
    end

    # Determine the content type of this response.
    #
    # @return [MediaTypeIdentifier]
    def content_type
      MediaTypeIdentifier.load(headers['Content-Type']).freeze
    end

    # Set the content type for this response.
    # @todo DRY this out (also used in Multipart::Part)
    #
    # @return [String]
    # @param [String,MediaTypeIdentifier] identifier
    def content_type=(identifier)
      headers['Content-Type'] = MediaTypeIdentifier.load(identifier).to_s
    end

    def handle; end

    def add_part(part, name = nil)
      @form_data ||= begin
        form = MIME::Multipart::FormData.new
        @headers.merge! form.headers.headers
        form
      end

      name ||= "part-#{part.object_id}"
      part.name = name
      @parts[name.to_s] = part
    end

    def response_name
      self.class.response_name
    end

    def format!; end

    def encode!
      case @body
      when Hash, Array
        # response payload is structured data; transform it into an entity using the handler
        # implied by the response's media type. If no handler is registered for this
        # name, assume JSON as a default handler.
        handlers = Praxis::Application.instance.handlers
        handler = (content_type && handlers[content_type.handler_name]) || handlers['json']
        @body = handler.generate(@body)
      end
    end

    def finish
      format!
      encode!

      @body = Array(@body)

      if @form_data
        @body << "\r\n" if @body.any? && @body.last !~ /\n$/

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
    def validate(action, validate_body: false)
      return if response_name == :validation_error

      unless (response_definition = action.responses[response_name])
        raise Exceptions::Validation, "Attempting to return a response with name #{response_name} " \
          'but no response definition with that name can be found'
      end
      response_definition.validate(self, validate_body: validate_body)
    rescue Exceptions::Validation => e
      ve = Application.instance.validation_handler.handle!(
        summary: 'Error validating response',
        exception: e,
        request: request,
        stage: 'response',
        errors: e.errors
      )
      body = ve.format!

      Responses::InternalServerError.new(body: body)
    end
  end
end
