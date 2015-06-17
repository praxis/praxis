module Praxis
  module RequestStages

    class Response < RequestStage

      def execute
        response = controller.response

        response.handle

        if Application.instance.config.praxis.validate_responses == true
          response.validate(action)
        end
      rescue Exceptions::Validation => e
        controller.response = validation_handler.handle!(
          summary: "Error validating response", 
          exception: e,
          request: request,
          stage: name
        )
        retry
      end

    end

  end
end
