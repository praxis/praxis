module Praxis
  module RequestStages

    class ValidateParamsAndHeaders < RequestStage
      attr_reader :parent

      def initialize(name, context, parent:)
        super
        @parent = parent
      end


      def path
        @_path ||= ( @parent.path + [name] )
      end

      def execute
        request.load_headers(CONTEXT_FOR[:headers])
        request.load_params(CONTEXT_FOR[:params])

        attribute_resolver = Attributor::AttributeResolver.new
        Attributor::AttributeResolver.current = attribute_resolver

        attribute_resolver.register("headers",request.headers)
        attribute_resolver.register("params",request.params)

        errors = request.validate_headers(CONTEXT_FOR[:headers])
        errors += request.validate_params(CONTEXT_FOR[:params])

        if errors.any?
          return Responses::ValidationError.new(summary: "Error validating request data", errors: errors)
        end
      end

    end

  end
end
