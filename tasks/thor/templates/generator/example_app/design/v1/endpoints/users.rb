# frozen_string_literal: true

module V1
  module Endpoints
    class Users
      include Praxis::EndpointDefinition
      # include AuthenticatedEndpoint

      media_type MediaTypes::User
      version '1'

      description 'Endpoints that allow the listing and manipulation of users'

      action :index do
        description 'List users'
        routing { get '' }
        params do
          attribute :fields, Praxis::Types::FieldSelector.for(MediaTypes::User),
                    description: 'Fields with which to render the result.'
          attribute :filters, Praxis::Types::FilteringParams.for(MediaTypes::User) do
            filter 'state', using: ['=', '!=']
            filter 'first_name', using: ['=', '!='], fuzzy: true
            filter 'last_name', using: ['=', '!='], fuzzy: true
          end
          attribute :pagination, Praxis::Types::PaginationParams.for(MediaTypes::User) do
            by_fields :uid, :first_name, :last_name
          end
          attribute :order, Praxis::Extensions::Pagination::OrderingParams.for(MediaTypes::User) do
            by_fields :uid, :last_name, :first_name
          end          
        end
        response :ok, media_type: Praxis::Collection.of(MediaTypes::User)
      end
    end
  end
end

