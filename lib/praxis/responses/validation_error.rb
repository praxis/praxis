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
          @body = {name: @exception.class.name, message: @exception.message}
        end
      end
    end

  end


  ApiDefinition.define do |api|
    api.register_response :validation_error do
      description "When parameter validation hits..."
      status 400
      media_type "application/json"
    end
  end

end
