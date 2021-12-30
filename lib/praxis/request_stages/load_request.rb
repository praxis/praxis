module Praxis
  module RequestStages
    class LoadRequest < RequestStage
      def execute
        request.coalesce_inputs!
      end
    end
  end
end
