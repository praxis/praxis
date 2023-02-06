# frozen_string_literal: true

module Praxis
  module Docs
    module OpenApi
      class SchemaObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#schema-object
        attr_reader :type

        def initialize(info:)
          @attribute_options = {}

          # info could be an attribute ... or a type
          if info.is_a?(Attributor::Attribute)
            @type = info.type
            # Save the options that might be attached to the attribute, to add them to the type schema later
            @attribute_options = info.options
          else
            @type = info
          end

          # Mediatypes have the description method, lower types don't
          @attribute_options[:description] = @type.description if @type.respond_to?(:description)
          @collection = type.respond_to?(:member_type)
        end

        def dump_example
          ex = type.example
          ex.respond_to?(:dump) ? ex.dump : ex
        end

        def dump_schema(shallow: false, allow_ref: false)
          # We will dump schemas for mediatypes by simply creating a reference to the components' section
          if type < Attributor::Container && ! (type < Praxis::Types::MultipartArray)
            if (type < Praxis::Blueprint || type < Attributor::Model) && allow_ref && !type.anonymous?
              # TODO: Technically OpenAPI/JSON schema support passing a description when pointing to a $ref (to override it)
              # However, it seems that UI browsers like redoc or elements have bugs where if that's done, they get into a loop and crash
              # so for now, we're gonna avoid overriding the description until that is solved
              # h = @attribute_options[:description] ? { 'description' => @attribute_options[:description] } : {}
              h = {}
              Praxis::Docs::OpenApiGenerator.instance.register_seen_component(type)
              h.merge!('$ref' => "#/components/schemas/#{type.id}")
            elsif @collection
              items = OpenApi::SchemaObject.new(info: type.member_type).dump_schema(allow_ref: allow_ref, shallow: false)
              h = @attribute_options[:description] ? { 'description' => @attribute_options[:description] } : {}
              h.merge!(type: 'array', items: items)
            else # Attributor::Struct, etc
              required_attributes = (type.describe[:requirements] || []).filter { |r| r[:type] == :all }.map { |r| r[:attributes] }.flatten.compact.uniq
              props = type.attributes.transform_values.with_index do |definition, index|
                # if type has an attribute in its requirements all, then it should be marked as required here
                field_name = type.attributes.keys[index]
                OpenApi::SchemaObject.new(info: definition).dump_schema(allow_ref: true, shallow: shallow)
              end
              h = { type: :object}
              h[:properties] = props if props.presence
              h[:required] = required_attributes unless required_attributes.empty?
            end
          else
            # OpenApi::SchemaObject.new(info:target).dump_schema(allow_ref: allow_ref, shallow: shallow)
            # TODO...we need to make sure we can use refs in the underlying components after the first level...
            # ... maybe we need to loop over the attributes if it's an object/struct?...
            h = type.as_json_schema(shallow: shallow, example: nil, attribute_options: @attribute_options)
          end

          # Tag on OpenAPI specific requirements that aren't already added in the underlying JSON schema model
          # Nullable: (it seems we need to ensure there is a null option to the enum, if there is one)
          is_nullable = @attribute_options[:null]
          h[:nullable] = true if is_nullable
          h

          # # TODO: FIXME: return a generic object type if the passed info was weird.
          # return { type: :object } unless info

          # h = {
          #   #type: convert_family_to_json_type( info[:type] )
          #   type: info[:type]
          #   #TODO: format?
          # }
          # # required prop!!!??
          # h[:default] = info[:default] if info[:default]
          # h[:pattern] = info[:regexp] if info[:regexp]
          # # TODO: there are other possible things we can do..maximum, minimum...etc

          # if h[:type] == :array
          #   # FIXME: ... hack it for MultiPart arrays...where there's no member attr
          #   member_type =  info[:type][:member_attribute]
          #   unless member_type
          #     member_type = { family: :hash}
          #   end
          #   h[:items] = SchemaObject.new(info: member_type ).dump_schema
          # end
          # h
        rescue StandardError => e
          puts "Error dumping schema #{e}"
        end

        def convert_family_to_json_type(praxis_type)
          case praxis_type[:family].to_sym
          when :string
            :string
          when :hash
            :object
          when :array # Warning! Multipart types are arrays!
            :array
          when :numeric
            jtypes = {
              'Attributor-Integer' => :integer,
              'Attributor-BigDecimal' => :integer,
              'Attributor-Float' => :number
            }
            jtypes[praxis_type[:id]]
          when :temporal
            :string
          when :boolean
            :boolean
          else
            raise "Unknown praxis family type: #{praxis_type[:family]}"
          end
        end
      end
    end
  end
end
