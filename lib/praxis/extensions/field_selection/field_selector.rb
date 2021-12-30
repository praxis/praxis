# frozen_string_literal: true

module Praxis
  module Extensions
    module FieldSelection
      class FieldSelector
        include Attributor::Type
        include Attributor::Dumpable

        def self.json_schema_type
          :string
        end

        def self.native_type
          self
        end

        def self.display_name
          'FieldSelector'
        end

        def self.family
          'string'
        end

        def self.for(media_type)
          unless media_type < Praxis::MediaType
            raise ArgumentError, "Invalid type: #{media_type.name} for FieldSelector. " +
                                 'Must be a subclass of MediaType'
          end

          ::Class.new(self) do
            @media_type = media_type
          end
        end

        def self.load(value, _context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
          return value if value.is_a?(native_type)

          if value.nil? || value.blank?
            new(true)
          else
            parsed = Attributor::FieldSelector.load(value)
            new(parsed)
          end
        end

        def self.example(context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
          fields = if media_type
                     media_type.attributes.keys.sample(3).join(',')
                   else
                     Attributor::FieldSelector.example(context, **options)
                   end
          self.load(fields)
        end

        def self.validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
          return [] unless media_type

          instance = self.load(value, context)
          instance.validate(context)
        end

        def self.dump(value, **_opts)
          self.load(value).dump
        end

        class << self
          attr_reader :media_type
        end

        attr_reader :fields

        def initialize(fields)
          @fields = fields
        end

        def dump(*_args)
          return '' if fields == true

          _dump(fields)
        end

        def _dump(fields)
          fields.each_with_object([]) do |(field, spec), array|
            array << if spec == true
                       field
                     else
                       "#{field}{#{_dump(spec)}}"
                     end
          end.join(',')
        end

        def validate(_context = Attributor::DEFAULT_ROOT_CONTEXT)
          errors = []
          return errors if fields == true

          _validate(self.class.media_type, fields)
        end

        def _validate(type, fields, context = Attributor::DEFAULT_ROOT_CONTEXT)
          errors = []
          fields.each do |name, field_spec|
            unless type.attributes.key?(name)
              errors << "Attribute with name #{name} not found in #{Attributor.type_name(type)}"
              next
            end

            next unless field_spec.is_a?(Hash)

            sub_context = context + [name]
            sub_attribute = type.attributes[name]
            sub_type = sub_attribute.type
            sub_type = sub_type.member_type if sub_attribute.type.respond_to?(:member_attribute)
            errors.push(*_validate(sub_type, field_spec, sub_context))
          end
          errors
        end
      end
    end
  end
end

# Alias it to a much shorter and sweeter name in the Types namespace.
module Praxis
  module Types
    FieldSelector = Praxis::Extensions::FieldSelection::FieldSelector
  end
end
