# frozen_string_literal: true

module Praxis
  module Responses
    class ValidationError < BadRequest
      def initialize(summary:, errors: nil, exception: nil, documentation: nil, **opts)
        super(**opts)
        @headers['Content-Type'] = 'application/json' # TODO: might want an error mediatype
        @errors = errors
        @errors = [exception.message] if !@errors && exception&.message # The exception message will the the only error if no errors are passed in
        @exception = exception
        @summary = summary
        @documentation = documentation
      end

      def format!
        @body = { name: 'ValidationError', summary: @summary }
        @body[:errors] = @errors if @errors

        @body[:cause] = { name: @exception.cause.class.name, message: @exception.cause.message } if @exception&.cause

        @body[:documentation] = @documentation if @documentation

        @body
      end
    end
  end

  ApiDefinition.define do |api|
    api.response_template :validation_error do
      description 'An error message indicating that one or more elements of the request did not match the API specification for the action'
      status 400
      media_type 'application/json'
    end
  end
end
