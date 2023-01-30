require_relative 'base'

module Resources
  class Book < Resources::Base
    model ::ActiveBook

    filters_mapping(
      name: :simple_name
    )

    property :name, dependencies: [:simple_name]
    def name
      record.simple_name
    end
  end
end