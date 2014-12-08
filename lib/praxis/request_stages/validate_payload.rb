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
        if request.action.payload
          begin
            request.load_payload(CONTEXT_FOR[:payload])
          rescue Attributor::AttributorException => e
            message = e.message
            message << ". For request Content-Type: '#{request.content_type}'"
            return Responses::ValidationError.new(exception: e, message: message)
          end
          Attributor::AttributeResolver.current.register("payload",request.payload)

          errors = request.validate_payload(CONTEXT_FOR[:payload])
          if errors.any?
            return Responses::ValidationError.new(errors: errors)
          end
        end
      end

    end

  end
end
