# frozen_string_literal: true

module V1
  module Resources
    class User < Praxis::Mapper::Resource
      model ::User

      # Mappings for the allowed filterd
      filters_mapping(
        'email': 'email',
        'first_name': 'first_name',        
        # Complex (convoluted?) mapping of state, just to show how we can modify and adapt the values/fields/operators
        'state': lambda do |spec|
          case spec[:value].to_s
          when 'pending' # Pending users do not have a uuid
            { name: :uuid, value: nil, op: spec[:op] }
          when 'active' # Active users do not have a uuid (so "flip" the original equality condition)
            opposite_op = spec[:op] == '=' ? '!=' : '='
            { name: :uuid, value: nil, op: opposite_op }
          else
            raise "Cannot filter users by state #{spec[:value]}"
          end
        end,
      )

      # Example of a property that depends on a differently named DB field
      property :uid, dependencies: %i[id]
      # To compute the full_name (method below) we need to load first and last names from the DB
      property :full_name, dependencies: %i[first_name last_name]

      def uid
        id # underlying id field of the model
      end

      # Computed attribute: if uuid nil, user in in a pending stat, else active
      def state 
        self.uuid.nil? ? 'pending' : 'active'
      end

      # Computed attribute the combines first and last
      def full_name
        [first_name, last_name].join(' ')
      end
    end
  end
end
