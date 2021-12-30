# frozen_string_literal: true
module Praxis
  module RequestStages
    class Validate < RequestStage
      def initialize(name, context, **opts)
        super
        # Add our sub-stages
        @stages = [
          RequestStages::ValidateParamsAndHeaders.new(:params_and_headers, context, parent: self),
          RequestStages::ValidatePayload.new(:payload, context, parent: self)
        ]
      end
    end
  end
end
