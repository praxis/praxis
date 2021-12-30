# frozen_string_literal: true
module Praxis
  module Extensions
    module FieldExpansion
      extend ActiveSupport::Concern

      included do
        Praxis::ActionDefinition.include ActionDefinitionExtension
      end

      def expanded_fields
        @expansion ||= request.action.expanded_fields(request, media_type)
      end

      module ActionDefinitionExtension
        extend ActiveSupport::Concern

        def expanded_fields(request, media_type)
          uses_fields = params && params.attributes.key?(:fields)
          fields = uses_fields ? request.params.fields.fields : true

          Praxis::FieldExpander.expand(media_type, fields)
        end
      end
    end
  end
end
