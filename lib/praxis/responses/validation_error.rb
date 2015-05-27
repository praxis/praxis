module Praxis

  module Responses

    class ValidationError < BadRequest
      def initialize(summary: , errors: nil, exception: nil, **opts)
        super(**opts)
        @headers['Content-Type'] = 'application/json' #TODO: might want an error mediatype
        @errors = errors
        unless @errors # The exception message will the the only error if no errors are passed in
           @errors = [exception.message] if exception && exception.message
         end
        @exception = exception
        @summary = summary
      end

      def format!
        @body = {name: 'ValidationError', summary: @summary }
        @body[:errors] = @errors if @errors

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
