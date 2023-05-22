# frozen_string_literal: true

class Book < Praxis::MediaType
  identifier 'application/vnd.acme.book'

  domain_model 'Resources::Book'

  attributes do
    attribute :id, Integer
    attribute :name, String
    attribute :simple_name, String
    attribute :category_uuid, String
    attribute :author, Author
    attribute :tags, Praxis::Collection.of(Tag)

    group :grouped do
      attribute :id
      attribute :name
      attribute :moar_tags, Praxis::Collection.of(Tag)
    end
  end
end
