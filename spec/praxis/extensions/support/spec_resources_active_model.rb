require 'active_record'

require 'praxis/mapper/active_model_compat'

# Creates a new in-memory DB, and the necessary tables (and mini-seeds) for the  models in this file
def create_tables

  ActiveRecord::Base.establish_connection(
      adapter:  'sqlite3',
      dbfile:  ':memory:',
      database: ':memory:'
  )
  
  ActiveRecord::Schema.define do
    ActiveRecord::Migration.suppress_messages do
      create_table :active_books do |table|
        table.column :simple_name, :string
        table.column :added_column, :string
        table.column :category_uuid, :string
        table.column :author_id, :integer
      end
  
      create_table :active_authors do |table|
        table.column :name, :string
      end
  
      create_table :active_categories do |table|
        table.column :uuid, :string
        table.column :name, :string
      end
  
      create_table :active_tags do |table|
        table.column :name, :string
      end
  
      create_table :active_taggings do |table|
        table.column :book_id, :integer
        table.column :tag_id, :integer
        table.column :label, :string, null: true
      end
    end
  end
end

create_tables

class ActiveBook < ActiveRecord::Base
  include Praxis::Mapper::ActiveModelCompat

  belongs_to :category, class_name: 'ActiveCategory', foreign_key: :category_uuid, primary_key: :uuid
  belongs_to :author, class_name: 'ActiveAuthor'
  has_many :taggings, class_name: 'ActiveTagging', foreign_key: :book_id
  has_many :tags, class_name: 'ActiveTag', through: :taggings
end

class ActiveAuthor < ActiveRecord::Base
  include Praxis::Mapper::ActiveModelCompat
  has_many :books, class_name: 'ActiveBook', foreign_key: :author_id
end

class ActiveCategory < ActiveRecord::Base
  include Praxis::Mapper::ActiveModelCompat
  has_many :books, class_name: 'ActiveBook', primary_key: :uuid, foreign_key: :category_uuid
end

class ActiveTag < ActiveRecord::Base
  include Praxis::Mapper::ActiveModelCompat
end

class ActiveTagging < ActiveRecord::Base
  include Praxis::Mapper::ActiveModelCompat
  belongs_to :book, class_name: 'ActiveBook', foreign_key: :book_id
  belongs_to :tag, class_name: 'ActiveTag', foreign_key: :tag_id
end


# A set of resource classes for use in specs
class ActiveBaseResource < Praxis::Mapper::Resource
end

class ActiveAuthorResource < ActiveBaseResource
  model ActiveAuthor

  property :display_name, dependencies: [:name]
end

class ActiveCategoryResource < ActiveBaseResource
  model ActiveCategory
end

class ActiveTagResource < ActiveBaseResource
  model ActiveTag
end

class ActiveBookResource < ActiveBaseResource
  model ActiveBook

  filters_mapping(
    id: :id,
    category_uuid: :category_uuid,
    'fake_nested.name': 'simple_name',
    'name': 'simple_name',
    'name_is_not': lambda do |spec| # Silly way to use a proc, but good enough for testing
      spec[:op] = '!='
      { simple_name: spec[:value] }
      end,
    'author.name': 'author.name',
    'taggings.label': 'taggings.label',
    'taggings.tag_id': 'taggings.tag_id',
    'tags.name': 'tags.name',
    'category.name': 'category.name',
    #'category.books.name': 'category.books.name',
  )
  # Forces to add an extra column (added_column)...and yet another (author_id) that will serve
  # to check that if that's already automatically added due to an association, it won't interfere or duplicate
  property :author, dependencies: [:author, :added_column, :author_id]

  property :name, dependencies: [:simple_name]
end


def seed_data
  cat1 = ActiveCategory.create( id: 1 , uuid: 'deadbeef1', name: 'cat1' )
  cat2 = ActiveCategory.create( id: 2 , uuid: 'deadbeef2', name: 'cat2' )
  
  author1 = ActiveAuthor.create(  id: 11, name: 'author1' )
  author2 = ActiveAuthor.create(  id: 22, name: 'author2' )
  
  tag_blue = ActiveTag.create(id: 1 , name: 'blue' )
  tag_red = ActiveTag.create(id: 2 , name: 'red' )
  tag_green = ActiveTag.create(id: 3 , name: 'green' )

  book1 = ActiveBook.create( id: 1 , simple_name: 'Book1', category_uuid: 'deadbeef1')
  book1.author = author1
  book1.category = cat1
  book1.save
  ActiveTagging.create(book: book1, tag: tag_blue, label: 'primary')
  ActiveTagging.create(book: book1, tag: tag_red)
  ActiveTagging.create(book: book1, tag: tag_green, label: 'primary')
  

  book2 = ActiveBook.create( id: 2 , simple_name: 'Book2', category_uuid: 'deadbeef1')
  book2.author = author2
  book2.category = cat2
  book2.save
  ActiveTagging.create(book: book2, tag: tag_red, label: 'primary')


  # More stuff

  10.times do |i|
    bid = 1000+i
    ActiveBook.create( id: bid , simple_name: "Book#{bid}")
  end

end

seed_data