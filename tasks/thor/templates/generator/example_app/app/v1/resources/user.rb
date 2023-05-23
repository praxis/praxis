# frozen_string_literal: true

module V1
  module Resources
    class User < Base
      model ::User

      # Define the name mapping from API filter params, to model attribute/associations
      # when they aren't 1:1 the same
      # filters_mapping(
      #   'label': 'association.label_name'
      # )

      # Add dependencies for resource attributes to other attributes and/or model associations
      # To compute the full_name (method below) we need to load first and last names from the DB
      property :full_name, dependencies: %i[first_name last_name]

      # Computed attribute that combines first and last
      def full_name
        [first_name, last_name].join(' ')
      end
      

      def self.create(payload)
        # Assuming the API field names directly map the the model attributes. Massage if appropriate.
        self.new(model.create(**payload.to_h))
      end

      def update(payload:)
        # Assuming the API field names directly map the the model attributes. Massage if appropriate.
        record.update(**payload.to_h)
        self
      end

      def delete
        record.destroy
        self
      end
    end
  end
end
