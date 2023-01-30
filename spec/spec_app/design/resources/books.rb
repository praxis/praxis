# frozen_string_literal: true

module ApiResources
  class Books
    include Praxis::EndpointDefinition

    media_type Book
    version '1.0'

    action :index do
      routing { get '' }
      params do
        attribute :fields, Praxis::Types::FieldSelector.for(Book), description: 'Fields with which to render the result.'
        attribute :filters, Praxis::Types::FilteringParams.for(Book) do
          filter 'author.name', using: %w[= != !], fuzzy: true
          filter 'tags.name', using: %w[= !=]
          filter 'author.id', using: %w[= !=]
        end
        attribute :order, Praxis::Extensions::Pagination::OrderingParams.for(Book) do
          by_fields :id, 'author.name'
        end
      end
      response :ok, media_type: Praxis::Collection.of(Book)
    end

    action :show do
      routing { get '/:id' }

      params do
        attribute :id, description: 'ID to find'
        attribute :fields, Praxis::Types::FieldSelector.for(Book), description: 'Fields with which to render the result.'
      end
      response :ok
    end
  end
end
