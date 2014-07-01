module Praxis
  module RequestStages

    class Action < RequestStage

      def execute
        response = controller.send(action.name, **request.params_hash)
        if response.kind_of? String
          controller.response.body = response
        else
          controller.response = response
        end

        controller.response.request = request
      end

    end

  end
end