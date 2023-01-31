require_relative 'base'

module Resources
  class Author < Resources::Base
    model ::ActiveAuthor

    order_mapping(
      'display_name': 'name',
    )
    property :display_name, dependencies: [:name]
  end
end
