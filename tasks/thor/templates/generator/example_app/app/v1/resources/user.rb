# frozen_string_literal: true

module V1
  module Resources
    class User < Base
      model ::User

      # To compute the full_name (method below) we need to load first and last names from the DB
      property :full_name, dependencies: %i[first_name last_name]

      # Computed attribute that combines first and last
      def full_name
        [first_name, last_name].join(' ')
      end
    end
  end
end
