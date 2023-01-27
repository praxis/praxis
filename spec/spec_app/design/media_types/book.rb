# frozen_string_literal: true

class Book < Praxis::MediaType
  identifier 'application/vnd.acme.book'

  domain_model 'Resources::Book'
  attributes do

    attribute :id, Integer
    attribute :name, String
    # belongs_to :category, class_name: 'ActiveCategory', foreign_key: :category_uuid, primary_key: :uuid
    attribute :author, Author

    # has_many :taggings, class_name: 'ActiveTagging', foreign_key: :book_id
    # has_many :primary_taggings, -> { where(label: 'primary') }, class_name: 'ActiveTagging', foreign_key: :book_id
  
    attribute :tags, Praxis::Collection.of(Tag)
    # has_many :primary_tags, class_name: 'ActiveTag', through: :primary_taggings, source: :tag
  end

end
