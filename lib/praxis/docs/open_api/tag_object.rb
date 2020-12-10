module Praxis
  module Docs
    module OpenApi
      class TagObject
        attr_reader :name, :description
        def initialize(name:,description: )
          @name = name
          @description = description
        end

        def dump
          {
            name: name,
            description: description,
            #externalDocs: ???,
          }
        end
      end
    end
  end
end
