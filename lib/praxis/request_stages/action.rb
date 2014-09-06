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
        nil # Action cannot return its OK request, as it would indicate the end of the stage chain
      end
            
    end

  end
end