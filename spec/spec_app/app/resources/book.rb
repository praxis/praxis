# frozen_string_literal: true

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

    # Make name go through another nested property, before getting to simple_name
    property :name, dependencies: [:nested_name]
    def name
      nested_name
    end

    property :nested_name, dependencies: [:simple_name]
    def nested_name
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

    property :grouped_moar_tags, as: :tags

    property :special, dependencies: [:simple_name]
    def special
      record.simple_name.reverse # just to make it different
    end
    property :multi, dependencies: [:simple_name]
    def multi
      record.simple_name.upcase # just to make it different
    end
  end
end
