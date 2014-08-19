module Praxis

  module Responses

    class ValidationError < BadRequest
      def initialize(errors: nil, exception: nil, **opts)
        super(**opts)
        @errors = errors
        @exception = exception
      end

      def format!
        if @errors
          @body = {name: 'ValidationError', errors: @errors}
        elsif @exception
          @body = {name: 'ValidationError', message: @exception.message}
          if @exception.cause
            @body[:cause] = {name: @exception.cause.class.name, message: @exception.cause.message}
          end
          @body
        end
      end
    end

  end


  ApiDefinition.define do |api|
    api.response_template :validation_error do
      description "When parameter validation hits..."
      status 400
      media_type "application/json"
    end
  end

end
