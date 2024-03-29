# frozen_string_literal: true

module Praxis
  module Docs
    module OpenApi
      class TagObject
        attr_reader :name, :description

        def initialize(name:, description:)
          @name = name
          @description = description
        end

        def dump
          h = description ? { description: description } : {}
          h.merge(
            name: name
            # externalDocs: ???,
          )
        end
      end
    end
  end
end
