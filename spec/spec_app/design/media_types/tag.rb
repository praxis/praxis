# frozen_string_literal: true

class Tag < Praxis::MediaType
  identifier 'application/vnd.acme.tag'

  domain_model 'Resources::Tag'
  attributes do
    attribute :name, String
    attribute :taggings, Praxis::Collection.of(Tagging)
  end
end
