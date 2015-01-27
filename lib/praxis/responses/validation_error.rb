module Praxis

  module Responses

    class ValidationError < BadRequest
      def initialize(errors: nil, exception: nil, message: nil, **opts)
        super(**opts)
        @headers['Content-Type'] = 'application/json' #TODO: might want an error mediatype
        @errors = errors
        @exception = exception
        @message = message || (exception && exception.message)
      end

      def format!
        if @errors
          @body = {name: 'ValidationError', errors: @errors}
        elsif @message
          @body = {name: 'ValidationError', message: @message}
        end

        if @exception && @exception.cause
          @body[:cause] = {name: @exception.cause.class.name, message: @exception.cause.message}
        end

        @body
      end
    end

  end


  ApiDefinition.define do |api|
    api.response_template :validation_error do
      description "An error message indicating that one or more elements of the request did not match the API specification for the action"
      status 400
      media_type "application/json"
    end
  end

end
