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
          use_fields = self.params && self.params.attributes.key?(:fields)
          use_view = self.params && self.params.attributes.key?(:view)

          # Determine what, if any, fields to display.
          fields = if use_fields
            request.params.fields.fields
          else
            true
          end

          # Determine the view that COULD be applicable.
          view = if use_view && (view_name = request.params.view)
            media_type.views[view_name.to_sym]
          else
            media_type.views[:default]
          end

          expandable = if fields == true
            # We want to show ALL of the available fields.
            # This can never be applied to the type (it's likely infinitely recursive).
            # So use view_name determimed above.
            view
          else
            # We want to show SOME of fields available on a view or type.
            if use_view && request.params.view
              # Use the requested view.
              view
            else
              # Use the type.
              media_type
            end
          end

          Praxis::FieldExpander.expand(expandable,fields)
        end
      end

    end
  end
end
