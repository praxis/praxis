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

    property_group :grouped, ::Book

    property :grouped_id, dependencies: [:id]
    def grouped_id
      id
    end

    property :grouped_name, dependencies: [:name]
    def grouped_name
      name
    end

    property :grouped_moar_tags, dependencies: [:tags]
    def grouped_moar_tags
      tags
    end

    # The problem with this one is that we're essentially materializing the values when we do this (i.e., if 'simple_name' was an expensive thing, we'd be calculating it here)
    # If that's a field that we're asking for, that's fine...but if it's not, we're calculating something that we don't need at all.
    def prefixed
      type_from_mediatype = ::Book.attribute.attributes[:prefixed].type
      type_from_mediatype.new(id: id, name: simple_name)
    end
  end
end
