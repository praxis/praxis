# frozen_string_literal: true

module Praxis
  module Docs
    module OpenApi
      class SchemaObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#schema-object
        attr_reader :type

        def initialize(info:)
          # info could be an attribute ... or a type?
          if info.is_a?(Attributor::Attribute)
            @type =  info.type
            @enum = info.options[:values]
            @nullable = info.options[:null]
          else
            @type = info
          end

          # Mediatypes have the description method, lower types don't
          @description = @type.description if @type.respond_to?(:description)
          @description ||= info.options[:description] if info.respond_to?(:options)
          @collection = type.respond_to?(:member_type)
        end

        def dump_example
          ex = type.example
          ex.respond_to?(:dump) ? ex.dump : ex
        end

        def dump_schema(shallow: false, allow_ref: false)
          # We will dump schemas for mediatypes by simply creating a reference to the components' section
          if type < Attributor::Container
            if (type < Praxis::Blueprint || type < Attributor::Model) && allow_ref && !type.anonymous?
              # TODO: Do we even need a description?
              h = @description ? { 'description' => @description } : {}

              Praxis::Docs::OpenApiGenerator.instance.register_seen_component(type)
              h.merge('$ref' => "#/components/schemas/#{type.id}")
            elsif @collection
              items = OpenApi::SchemaObject.new(info: type.member_type).dump_schema(allow_ref: allow_ref, shallow: false)
              h = @description ? { description: @description } : {}
              h.merge(type: 'array', items: items)
            else
              # Object
              props = type.attributes.each_with_object({}) do |(name, definition), hash|
                schema = OpenApi::SchemaObject.new(info: definition).dump_schema(allow_ref: true, shallow: shallow)
                schema[:nullable] = true if definition.options[:null]
                hash[name] = schema
              end
              { type: :object, properties: props } # TODO: Example?
            end
          else
            # OpenApi::SchemaObject.new(info:target).dump_schema(allow_ref: allow_ref, shallow: shallow)
            # TODO...we need to make sure we can use refs in the underlying components after the first level...
            # ... maybe we need to loop over the attributes if it's an object/struct?...
            schema = type.as_json_schema(shallow: shallow, example: nil)
            # TODO: should this sort of logic be moved into as_json_schema?
            schema.merge!(enum: @enum) if @enum
            schema.merge!(nullable: true) if @nullable
            schema
          end

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
