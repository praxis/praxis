# frozen_string_literal: true

require 'forwardable'

module Praxis
  module Extensions
    module Pagination
      class OrderingParams
        include Attributor::Type
        include Attributor::Dumpable
        extend Forwardable

        def_delegators :items, :empty?

        # DSL for restricting how to order.
        # It allows the concrete list of the fields one can use (through 'by_fields')
        # It also allows to enforce that list for all positions of the ordering definition (through 'enforce_for :all|:first')
        #  By default, only the first ordering position will be subject to that enforcement (i.e., 'enforce_for :first' is the default)
        # Example
        #
        # attribute :order, Praxis::Types::OrderingParams.for(MediaTypes::Bar) do
        #   by_fields :id, :name
        #   enforce_for :all
        # end
        class DSLCompiler < Attributor::DSLCompiler
          def by_fields(*fields)
            requested = fields.map(&:to_sym)

            errors = []
            requested.each do |field|
              if (failed_field = self.class.validate_field(target.media_type, field.to_s.split('.').map(&:to_sym)))
                errors += ["Cannot order by field: '#{field}'. It seems that the '#{failed_field}' attribute is not defined in the current #{target.media_type} structure (or its subtree)."]
              end
            end
            raise errors.join('\n') unless errors.empty?

            target.fields_allowed = requested
          end

          def enforce_for(which)
            case which.to_sym
            when :all
              target.enforce_all = true
            when :first
              # nothing, that's the default
            else
              raise "Error: unknown parameter for the 'enforce_for' : #{which}. Only :all or :first are allowed"
            end
          end

          def self.validate_field(type, path)
            main, rest = path
            next_attribute = type.respond_to?(:member_attribute) ? type.member_type.attributes[main] : type.attributes[main]

            return main unless next_attribute

            return nil if rest.nil?

            validate_field(next_attribute.type, rest)
          end
        end

        # Configurable DEFAULTS
        @enforce_all_fields = false

        def self.enforce_all_fields(newval = nil)
          newval ? @enforce_all_fields = newval : @enforce_all_fields
        end

        # Ordering type that allows you to specify the ordering characteristing of a requested listing
        # Ordering is based on given mediatype, which allows for ensuring validation of type names etc.

        # Syntax (similar to json-api)
        # * One can specify ordering based on several fields (to resolve tie breakers) by separating them with commas
        # * Requesting a descending order can be done by adding a `-` before the field name. Prepending a `+` enforces
        #   ascending order (which is the default if no sign is specified)
        # Example:
        # `name,last_name,-birth_date`

        # Abstract class, which needs to be used by subclassing it through the .for method, to link it to a particular
        # MediaType, so that the field name checking and value coercion can be performed
        class << self
          attr_reader :media_type
          attr_accessor :fields_allowed, :enforce_all # True when we need to enforce the allowed fields at all ordering positions

          def for(media_type, **_opts)
            unless media_type < Praxis::MediaType
              raise ArgumentError, "Invalid type: #{media_type.name} for Ordering. " \
                'Must be a subclass of MediaType'
            end

            ::Class.new(self) do
              @media_type = media_type
              # Default is to only enforce the allowed fields in the first ordering position (the one typicall uses an index if there)
              @enforce_all = OrderingParams.enforce_all_fields
            end
          end
        end

        attr_reader :items

        def self.json_schema_type
          :string
        end

        def self.native_type
          self
        end

        def self.name
          'Praxis::Types::OrderingParams'
        end

        def self.display_name
          'Ordering'
        end

        def self.family
          'string'
        end

        def self.constructable?
          true
        end

        def self.construct(pagination_definition, **options)
          return self if pagination_definition.nil?

          DSLCompiler.new(self, **options).parse(*pagination_definition)
          self
        end

        def self.example(_context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
          fields = if media_type
                     chosen_set = if enforce_all
                                    fields_allowed.sample(2)
                                  else
                                    starting_set = fields_allowed.sample(1)
                                    simple_attrs = media_type.attributes.select do |_k, attr|
                                      attr.type == Attributor::String || attr.type < Attributor::Numeric || attr.type < Attributor::Temporal
                                    end.keys
                                    starting_set + simple_attrs.reject { |attr| attr == starting_set.first }.sample(1)
                                  end
                     chosen_set.each_with_object([]) do |chosen, arr|
                       sign = rand(10) < 5 ? '-' : ''
                       arr << "#{sign}#{chosen}"
                     end.join(',')
                   else
                     'name,last_name,-birth_date'
                   end
          load(fields)
        end

        def self.validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
          instance = load(value, context)
          instance.validate(context)
        end

        def self.load(order, _context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
          return order if order.is_a?(native_type)

          parsed_order = {}
          unless order.nil?
            parsed_order = order.split(',').each_with_object([]) do |order_string, arr|
              item = case order_string[0]
                     when '-'
                       { desc: order_string[1..].to_s }
                     when '+'
                       { asc: order_string[1..].to_s }
                     else
                       { asc: order_string.to_s }
                     end
              arr.push item
            end
          end

          new(parsed_order)
        end

        def self.dump(value, **_opts)
          load(value).dump
        end

        def self.describe(_root = false, example: nil)
          hash = super

          if fields_allowed
            hash[:fields_allowed] = fields_allowed
            hash[:enforced_for] = enforce_all ? :all : :first
          end

          hash
        end

        def initialize(parsed)
          @items = parsed
        end

        def validate(_context = Attributor::DEFAULT_ROOT_CONTEXT)
          return [] if items.blank?

          errors = []
          if self.class.fields_allowed
            # Validate against the enforced components (either all, or just the first one)
            enforceable_items = self.class.enforce_all ? items : [items.first]

            enforceable_items.each do |spec|
              _dir, field = spec.first
              field = field.to_sym
              next if self.class.fields_allowed.include?(field)

              field_path = field.to_s.split('.').map(&:to_sym)
              errors << if valid_attribute_path?(self.class.media_type, field_path)
                          "Ordering by field \'#{field}\' in media type #{self.class.media_type.name} is disallowed. Ordering is only allowed using the following fields: " +
                          self.class.fields_allowed.map { |f| "\'#{f}\'" }.join(', ').to_s
                        else
                          "Ordering by field \'#{field}\' is not possible as this field is not reachable from " \
                          "media type #{self.class.media_type.name}"
                        end
            end
          end

          errors
        end

        def dump
          items.each_with_object([]) do |spec, arr|
            dir, field = spec.first
            arr << if dir == :desc
                     "-#{field}"
                   else
                     field
                   end
          end.join(',')
        end

        def each(&block)
          items.each(&block)
        end

        # Looks up if the given path (with symbol attribute names at each component) is actually
        # a valid path from the given mediatype
        def valid_attribute_path?(media_type, path)
          first, *rest = path
          # Get the member type if this is a collection
          media_type = media_type.member_type if media_type.respond_to?(:member_attribute)
          if (attribute = media_type.attributes[first])
            rest.empty? ? true : valid_attribute_path?(attribute.type, rest)
          else
            false
          end
        end
      end
    end
  end
end

# Alias it to a much shorter and sweeter name in the Types namespace.
module Praxis
  module Types
    OrderingParams = Praxis::Extensions::Pagination::OrderingParams
  end
end
