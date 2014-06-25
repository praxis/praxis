module Praxis
  module RequestStages

    class Response < RequestStage

      def execute
        response = controller.response

        unless action.allowed_responses.include?(response.definition)
          raise "response #{response.name.inspect} is not allowed for #{action.name.inspect}"
        end

        response.handle
        response.validate(action)
      end

    end

  end
end
