module Praxis
  module Extensions
    module Pagination
      class OrderingParams
        include Attributor::Type
        include Attributor::Dumpable

        delegate :empty?, to: :items
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
            non_matching = requested - target.media_type.attributes.keys
            unless non_matching.empty?
              raise "Error, you've requested to order by fields that do not exist in the mediatype!\n" \
              "The following #{non_matching.size} field/s do not exist in media type #{target.media_type.name} :\n" +
                    non_matching.join(',').to_s
            end
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
        end

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
          attr_accessor :fields_allowed
          attr_accessor :enforce_all # True when we need to enforce the allowed fields at all ordering positions

          def for(media_type, **_opts)
            unless media_type < Praxis::MediaType
              raise ArgumentError, "Invalid type: #{media_type.name} for Ordering. " \
                "Must be a subclass of MediaType"
            end

            ::Class.new(self) do
              @media_type = media_type
              if media_type
                # By default all fields in the mediatype are allowed (but defining a DSL block will override it to more specific ones)
                @fields_allowed = media_type.attributes.keys
              end
              # Default is to only enforce the allowed fields in the first ordering position (the one typicall uses an index if there)
              @enforce_all = OrderingParams.enforce_all_fields
            end
          end
        end

        attr_reader :items

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

          DSLCompiler.new(self, options).parse(*pagination_definition)
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
                                    starting_set + simple_attrs.select { |attr| attr != starting_set.first }.sample(1)
                                  end
                    chosen_set.each_with_object([]) do |chosen, arr|
                      sign = rand(10) < 5 ? "-" : ""
                      arr << "#{sign}#{chosen}"
                    end.join(',')
                  else
                    "name,last_name,-birth_date"
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
              item = if order_string[0] == '-'
                      { desc: order_string[1..-1].to_s }
                    elsif order_string[0] == '+'
                      { asc: order_string[1..-1].to_s }
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
              next unless !self.class.fields_allowed.include?(field)
              errors << if self.class.media_type.attributes.key?(field)
                          "Ordering by field \'#{field}\' is disallowed. Ordering is only allowed using the following fields: " +
                          self.class.fields_allowed.map { |f| "\'#{f}\'" }.join(', ').to_s
                        else
                          "Ordering by field \'#{field}\' is not possible as this field does not exist in " \
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

        def each
          items.each do |item|
            yield item
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
