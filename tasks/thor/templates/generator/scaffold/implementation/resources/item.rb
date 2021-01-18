# frozen_string_literal: true

module <%= version_module %>
  module Resources
    class <%= singular_class %> < Praxis::Mapper::Resource
      model ::<%= singular_class %> #Change it to the appropriate DB model class

      # Define the name mapping from API filter params, to model attribute/associations
      # when they aren't 1:1
      # filters_mapping(
      #   'name': 'name',
      #   'label': 'association.label_name'
      # )

      # Add dependencies for resource attributes to other attributes and/or model associations
      # property :href, dependencies: %i[id]
    end
  end
end