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
      end

    end

  end
end
