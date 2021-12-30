# frozen_string_literal: true
module Praxis
  class Collection < Attributor::Collection
    include Types::MediaTypeCommon

    def self.of(type)
      return type::Collection if defined?(type::Collection)

      klass = super
      klass.anonymous_type

      if type < Praxis::Types::MediaTypeCommon
        klass.member_type type
        type.const_set :Collection, klass
      else
        raise 'Praxis::Collection.of() for non-MediaTypes is unsupported. Use Attributor::Collection.of() instead.'
      end
    end

    def self.member_type(type = nil)
      unless type.nil?
        @member_type = type
        identifier(type.identifier + ';type=collection') unless type.identifier.nil?
      end

      @member_type
    end

    def self.domain_model
      @member_type.domain_model
    end

    def self.json_schema_type
      :array
    end

    def self.as_json_schema(**_args)
      the_type = @attribute && @attribute.type || member_type
      {
        type: json_schema_type,
        items: { '$ref': "#/components/schemas/#{the_type.id}" }
      }
    end
  end
end
