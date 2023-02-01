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
        attribute :filters, Praxis::Types::FilteringParams.for(Author) do
          filter 'books.name', using: %w[= != !], fuzzy: true
          filter 'id', using: %w[= !=]
        end
        attribute :order, Praxis::Extensions::Pagination::OrderingParams.for(Author) do
          by_fields :id, :name, 'books.name'
        end
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
