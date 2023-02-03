# frozen_string_literal: true

class BookGroup < Praxis::BlueprintGroup
  domain_model 'Resources::Book'
  attributes do
    attribute :id, Integer
    attribute :name, String
    attribute :simple_name, String
  end
end

class Book < Praxis::MediaType
  identifier 'application/vnd.acme.book'

  domain_model 'Resources::Book'

  attributes do
    attribute :id, Integer
    attribute :name, String
    attribute :simple_name, String
    attribute :category_uuid, String

    # belongs_to :category, class_name: 'ActiveCategory', foreign_key: :category_uuid, primary_key: :uuid
    attribute :author, Author

    # has_many :taggings, class_name: 'ActiveTagging', foreign_key: :book_id
    # has_many :primary_taggings, -> { where(label: 'primary') }, class_name: 'ActiveTagging', foreign_key: :book_id
    attribute :tags, Praxis::Collection.of(Tag)
    # has_many :primary_tags, class_name: 'ActiveTag', through: :primary_taggings, source: :tag

    attribute :grouped, Praxis::BlueprintGroup.for(Book) do
      attribute :id
      attribute :name
    end
  end
end
