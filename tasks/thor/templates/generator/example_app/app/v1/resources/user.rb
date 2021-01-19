# frozen_string_literal: true

module V1
  module Resources
    class User < Praxis::Mapper::Resource
      model ::User

      # Mappings for the allowed filters
      filters_mapping(
        'uuid': 'uuid',
        'first_name': 'first_name',
        'last_name': 'last_name',
        'email': 'email'
      )

      # To compute the full_name (method below) we need to load first and last names from the DB
      property :full_name, dependencies: %i[first_name last_name]


      # Computed attribute the combines first and last
      def full_name
        [first_name, last_name].join(' ')
      end
    end
  end
end
