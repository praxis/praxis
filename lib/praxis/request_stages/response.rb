module Praxis
  module RequestStages

    class Response < RequestStage

      def execute
        response = controller.response

        unless action.responses.include?(response.response_name)
          raise Exceptions::InvalidResponseException.new(
            "Response #{response.name.inspect} is not allowed for #{action.name.inspect}"
          )
        end

        response.handle

        praxis_config = Application.instance.config.praxis
        unless praxis_config && praxis_config.validate_responses == false
          response.validate(action)
        end
      end

    end

  end
end
