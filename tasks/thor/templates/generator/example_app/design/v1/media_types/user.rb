# frozen_string_literal: true

module V1
  module MediaTypes
    class User < Praxis::MediaType
      identifier 'application/json'

      domain_model 'V1::Resources::User'
      description 'A user in the system'

      attributes do
        attribute :id, Integer
        attribute :uuid, String
        attribute :email, String
        attribute :first_name, String
        attribute :last_name, String
      end
    end
  end
end

