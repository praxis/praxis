require_relative 'base'

module Resources
  class Book < Resources::Base
    model ::ActiveBook

    filters_mapping(
      name: :simple_name
    )

    order_mapping(
      name: 'simple_name',
      writer: 'author'
    )

    property :name, dependencies: [:simple_name]
    def name
      record.simple_name
    end

    property :grouped, dependencies: [:simple_name, :category_uuid] # TODO: Dependency resolution should have kicked in when asking for 'grouped' without any inner ones...
    def grouped
      self
    end
  end
end
