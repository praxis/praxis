# frozen_string_literal: true

class Author < Praxis::MediaType
  identifier 'application/vnd.acme.author'

  domain_model 'Resources::Author'
  attributes do
    attribute :id, Integer
    attribute :name, String
    attribute :display_name, String
    attribute :books, Praxis::Collection.of(Book)
  end
end
