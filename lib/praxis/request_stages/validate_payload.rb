# frozen_string_literal: true

module Praxis
  module RequestStages
    class ValidatePayload < RequestStage
      attr_reader :parent

      def initialize(name, context, parent:)
        super
        @parent = parent
      end

      def path
        @path ||= (@parent.path + [name])
      end

      def execute
        return unless request.action.payload

        begin
          request.load_payload(CONTEXT_FOR[:payload])
        rescue StandardError => e
          message = "Error loading payload. Used Content-Type: '#{request.content_type}'"
          return validation_handler.handle!(
            exception: e,
            summary: message,
            request: request,
            stage: name
          )
        end

        errors = request.validate_payload(CONTEXT_FOR[:payload])
        return unless errors.any?

        validation_handler.handle!(
          summary: 'Errors validating payload data',
          errors: errors,
          request: request,
          stage: name
        )
      end
    end
  end
end
