module Praxis
  module Extensions
    module FieldExpansion
      extend ActiveSupport::Concern

      included do
        Praxis::ActionDefinition.send(:include, ActionDefinitionExtension)
      end

      def expanded_fields
        @expansion ||= request.action.expanded_fields(self.request, self.media_type)
      end

      module ActionDefinitionExtension
        extend ActiveSupport::Concern

        def expanded_fields(request, media_type)
          uses_fields = self.params && self.params.attributes.key?(:fields)
          fields = uses_fields ? request.params.fields.fields : true

          Praxis::FieldExpander.expand(media_type,fields)
        end
      end
    end
  end
end
