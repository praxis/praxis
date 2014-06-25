module Praxis
  module RequestStages

    class ValidatePayload < RequestStage

      attr_reader :parent

      def initialize(name, context, parent:)
        super
        @parent = parent
      end

      def path
        @parent.path + [name]
      end


      def execute
        # TODO: handle multipart requests
        if request.action.payload
          request.load_payload(CONTEXT_FOR[:payload])
          Attributor::AttributeResolver.current.register("payload",request.payload)
          request.validate_payload(CONTEXT_FOR[:payload])
        end
      end

    end

  end
end
