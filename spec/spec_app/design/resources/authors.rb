# frozen_string_literal: true

module ApiResources
  class Authors
    include Praxis::EndpointDefinition

    media_type Author
    version '1.0'

    action :index do
      routing { get '' }
      params do
        attribute :fields, Praxis::Types::FieldSelector.for(Author), description: 'Fields with which to render the result.'
        attribute :filters, Praxis::Types::FilteringParams.for(Author) # No block for allowing any filtering
        attribute :order, Praxis::Extensions::Pagination::OrderingParams.for(Author) # No block for allowing any sorting
        attribute :pagination, Praxis::Types::PaginationParams.for(Author) # No block for allowing any field pagination
      end
      response :ok, media_type: Praxis::Collection.of(Author)
    end

    action :show do
      routing { get '/:id' }

      params do
        attribute :id, description: 'ID to find'
        attribute :fields, Praxis::Types::FieldSelector.for(Author), description: 'Fields with which to render the result.'
      end
      response :ok
    end
  end
end
