
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
                "Must be a subclass of MediaType"
            end

            ::Class.new(self) do
              @media_type = media_type
            end
          end

          def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
            return value if value.kind_of?(self.native_type)

            if value.nil? || value.blank?
              self.new(true)
            else
              parsed = Attributor::FieldSelector.load(value)
              self.new(parsed)
            end
          end

          def self.example(context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
            fields = if media_type
              media_type.attributes.keys.sample(3).join(',')
            else
              Attributor::FieldSelector.example(context,**options)
            end
            self.load(fields)
          end

          def self.validate(value, context=Attributor::DEFAULT_ROOT_CONTEXT, _attribute=nil)
            return [] unless media_type
            instance = self.load(value, context)
            instance.validate(context)
          end

          def self.dump(value,**opts)
            self.load(value).dump
          end

          class << self
            attr_reader :media_type
          end

          attr_reader :fields

          def initialize(fields)
            @fields = fields
          end

          def dump(*args)
            return '' if self.fields == true
            _dump(self.fields)
          end

          def _dump(fields)
            fields.each_with_object([]) do |(field, spec), array|
              if spec == true
                array << field
              else
                array << "#{field}{#{_dump(spec)}}"
              end
            end.join(',')
          end

          def validate(context=Attributor::DEFAULT_ROOT_CONTEXT)
            errors = []
            return errors if self.fields == true
            _validate(self.class.media_type, fields)
          end

          def _validate(type, fields, context=Attributor::DEFAULT_ROOT_CONTEXT)
            errors = []
            fields.each do |name, field_spec|
              unless type.attributes.key?(name)
                errors << "Attribute with name #{name} not found in #{Attributor.type_name(type)}"
                next
              end

              if field_spec.kind_of?(Hash)
                sub_context = context + [name]
                sub_attribute = type.attributes[name]
                sub_type = sub_attribute.type
                if sub_attribute.type.respond_to?(:member_attribute)
                  sub_type = sub_type.member_type
                end
                errors.push(*_validate(sub_type,field_spec, sub_context))
              end
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
