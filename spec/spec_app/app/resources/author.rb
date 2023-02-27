require_relative 'base'

module Resources
  class Author < Resources::Base
    model ::ActiveAuthor

    filters_mapping(
      'books.name': 'books.name'
    )
    order_mapping(
      'display_name': 'name'
    )
    property :display_name, dependencies: [:name]

    def display_name
      record.name
    end
  end
end
