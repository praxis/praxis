module Praxis
  module RequestStages
    class ValidateParamsAndHeaders < RequestStage
      attr_reader :parent

      def initialize(name, context, parent:)
        super
        @parent = parent
      end

      def path
        @_path ||= (@parent.path + [name])
      end

      def execute
        begin
          request.load_headers(CONTEXT_FOR[:headers])
        rescue StandardError => e
          message = 'Error loading headers.'
          return validation_handler.handle!(
            exception: e,
            summary: message,
            request: request,
            stage: name
          )
        end

        begin
          request.load_params(CONTEXT_FOR[:params])
        rescue Attributor::AttributorException => e
          message = 'Error loading params.'
          return validation_handler.handle!(
            exception: e,
            summary: message,
            request: request,
            stage: name
          )
        end

        errors = request.validate_headers(CONTEXT_FOR[:headers])
        errors += request.validate_params(CONTEXT_FOR[:params])
        if errors.any?
          message = 'Error validating request data.'
          validation_handler.handle!(
            summary: message,
            errors: errors,
            request: request,
            stage: name
          )
        end
      end
    end
  end
end
