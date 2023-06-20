# frozen_string_literal: true

module Praxis
  module Docs
    module OpenApi
      class SchemaObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#schema-object
        attr_reader :type, :attribute

        def initialize(info:)
          # info could be an attribute ... or a type
          # We will always try to work with the attribute if it is there, otherwise, we'll use type underneath
          if info.is_a?(Attributor::Attribute)
            @type = info.type
            @attribute = info
          else
            @type = info
          end

          @collection = type.respond_to?(:member_type)
        end

        def dump_example
          ex = (attribute || type).example
          ex.respond_to?(:dump) ? ex.dump : ex
        end

        def dump_schema(shallow: false, allow_ref: false)
          important_options = %i[description null]
          # Compile all options from the underlying tye and attribute (if any), translating them
          # to OpenAPI schema options with the x- prefix for our custom ones
          base_options = _slice_options(type, important_options)
          base_options.merge! _slice_options(type, Attributor::Attribute.custom_options, prefix: 'x')
          if attribute
            base_options.merge! _slice_options(attribute, important_options, prefix: 'x')
            base_options.merge! _slice_options(attribute, Attributor::Attribute.custom_options, prefix: 'x')
          end
          # Tag on OpenAPI specific requirements that aren't already added in the underlying JSON schema model
          # Nullable: (it seems we need to ensure there is a null option to the enum, if there is one)
          if base_options.key?(:null)
            base_options[:nullable] = Attributor::Attribute::nullable_attribute?(base_options)
            base_options.delete(:null)
          end

          # We will dump schemas for mediatypes by simply creating a reference to the components' section
          if type < Attributor::Container && !(type < Praxis::Types::MultipartArray)
            if (type < Praxis::Blueprint || type < Attributor::Model) && allow_ref && !type.anonymous?
              # NOTE: Technically OpenAPI/JSON schema support passing a description when pointing to a $ref (to override it)
              # However, it seems that UI browsers like redoc or elements have bugs where if that's done, they get into a loop and crash
              # so for now, we're gonna avoid overriding the description until that is solved
              base_options.delete(:description)
              Praxis::Docs::OpenApiGenerator.instance.register_seen_component(type)
              base_options.merge!('$ref' => "#/components/schemas/#{type.id}")
            elsif @collection
              items = OpenApi::SchemaObject.new(info: type.member_type).dump_schema(allow_ref: allow_ref, shallow: false)
              base_options.merge!(type: 'array', items: items)
            else # Attributor::Struct, etc
              # Requirements are reported at the outter schema layer, we we need to gather them from the description here
              reqs = type < Praxis::Blueprint ? type.attribute.type.requirements : type.requirements
              # Full requirements specified at the struct level that apply to all are considered required attributes
              required_attributes = (reqs || []).filter { |r| r.type == :all }.map(&:attr_names).flatten.compact
              # Also, if any inner attribute has the required: true option, that, obviously means required as well
              sub_attributes = (attribute || type).attributes
              direct_required = sub_attributes ? sub_attributes.select { |_, a| a.options[:required] == true }.keys : []
              required_attributes.concat(direct_required)
              required_attributes.uniq!
              props = sub_attributes.transform_values do |definition|
                OpenApi::SchemaObject.new(info: definition).dump_schema(allow_ref: true, shallow: shallow)
              end

              base_options.merge!(type: :object)
              base_options[:properties] = props if props.presence
              base_options[:required] = required_attributes unless required_attributes.empty?
            end
          else
            desc = (attribute || type).as_json_schema(shallow: shallow, example: nil)
            # OpenApi::SchemaObject.new(info:target).dump_schema(allow_ref: allow_ref, shallow: shallow)
            # TODO...we need to make sure we can use refs in the underlying components after the first level...
            # ... maybe we need to loop over the attributes if it's an object/struct?...
            base_options.merge!(desc)
          end

          base_options
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

        def _slice_options(object, names, prefix: nil)
          subset = object.options.slice(*names)
          return subset if prefix.nil?

          subset.transform_keys do |key|
            "#{prefix}-#{key}".to_sym
          end
          subset
        end
      end
    end
  end
end
