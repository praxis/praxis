# frozen_string_literal: true

module Praxis
  module Extensions
    module FieldExpansion
      extend ActiveSupport::Concern

      included do
        Praxis::ActionDefinition.include ActionDefinitionExtension
      end

      def expanded_fields
        @expanded_fields ||=
          begin
            expansion_filter = respond_to?(:display_attribute?) ? method(:display_attribute?) : nil
            request.action.expanded_fields(request, media_type, expansion_filter)
          end
      end

      module ActionDefinitionExtension
        extend ActiveSupport::Concern

        def expanded_fields(request, media_type, expansion_filter)
          uses_fields = params&.attributes&.key?(:fields)
          fields = uses_fields ? request.params.fields.fields : true
          Praxis::FieldExpander.expand(media_type, fields, expansion_filter)
        end
      end
    end
  end
end
