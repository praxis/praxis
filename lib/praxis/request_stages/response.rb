module Praxis
  module RequestStages

    class Response < RequestStage
      WHITELIST_RESPONSES = [:validation_error] 

      def execute
        response = controller.response


        unless action.responses.include?(response.response_name) || WHITELIST_RESPONSES.include?(response.response_name)
          raise Exceptions::InvalidResponse.new(
            "Response #{response.name.inspect} is not allowed for #{action.name.inspect}"
          )
        end

        response.handle

        praxis_config = Application.instance.config.praxis
        unless praxis_config && praxis_config.validate_responses == false
          response.validate(action)
        end
      rescue Exceptions::Validation => e
        controller.response = Responses::ValidationError.new(exception: e)
        retry 
      end

    end

  end
end
