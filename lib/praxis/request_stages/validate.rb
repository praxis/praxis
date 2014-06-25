module Praxis
  module RequestStages

    class Validate < RequestStage

      def setup!
        @stages << RequestStages::ValidateParamsAndHeaders.new(:params_and_headers, context, parent: self)
        @stages << RequestStages::ValidatePayload.new(:payload, context, parent: self)
      end

    end

  end
end
