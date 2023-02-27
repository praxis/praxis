# frozen_string_literal: true

module Praxis
  class BlueprintAttributeGroup < Blueprint
    def self.constructable?
      true
    end

    # Construct a new subclass, using attribute_definition to define attributes.
    def self.construct(attribute_definition, options = {})
      return self if attribute_definition.nil?

      reference_type = @media_type
      # Construct a group-derived class with the given mediatype as the reference
      ::Class.new(self) do
        @reference = reference_type
        attributes(**options, &attribute_definition)
      end
    end

    def self.for(media_type)
      return media_type::AttributeGrouping if defined?(media_type::AttributeGrouping) # Cache the grouping class

      ::Class.new(self) do
        @media_type = media_type
      end
    end
  end
end
