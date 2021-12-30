module Praxis
  module RequestStages
    class Response < RequestStage
      def execute
        response = controller.response

        response.handle

        if Application.instance.config.praxis.validate_responses == true
          validate_body = Application.instance.config.praxis.validate_response_bodies

          response.validate(action, validate_body: validate_body)
        end
      rescue Exceptions::Validation => e
        controller.response = validation_handler.handle!(
          summary: 'Error validating response',
          exception: e,
          request: request,
          stage: name,
          errors: e.errors
        )
        retry
      end
    end
  end
end
