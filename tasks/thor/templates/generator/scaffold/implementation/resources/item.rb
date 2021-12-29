# frozen_string_literal: true

module <%= version_module %>
  module Resources
    class <%= singular_class %> < Base
      model ::<%= singular_class %> # Change it if it maps to a different DB model class

      # Define the name mapping from API filter params, to model attribute/associations
      # when they aren't 1:1 the same
      # filters_mapping(
      #   'label': 'association.label_name'
      # )

      # Add dependencies for resource attributes to other attributes and/or model associations
      # property :href, dependencies: %i[id]

      <%- if action_enabled?(:create) -%>
      def self.create(payload)
        # Assuming the API field names directly map the the model attributes. Massage if appropriate.
        self.new(model.create(**payload.to_h))
      end
      <%- end -%>

      <%- if action_enabled?(:update) -%>
      def self.update(id:, payload:)
        record = model.find_by(id: id)
        return nil unless record
        # Assuming the API field names directly map the the model attributes. Massage if appropriate.
        record.update(**payload.to_h)
        self.new(record)
      end
      <%- end -%>

      <%- if action_enabled?(:delete) -%>
      def self.delete(id:)
        record = model.find_by(id: id)
        return nil unless record
        record.destroy
        self.new(record)
      end
      <%- end -%>  
    end
  end
end