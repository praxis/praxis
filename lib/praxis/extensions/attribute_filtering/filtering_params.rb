# frozen_string_literal: true
require 'praxis/extensions/attribute_filtering/filters_parser'

#
# Attributor type to define and handle the language to express filtering attributes in listings.
# Commonly used in a query string parameter value for listing calls.
# 
# The type allows you to restrict the allowable fields (and their types) based on an existing Mediatype.
# It also alows you to define exacly what fields (from that MediaType) are allowed, an what operations are
# supported for each of them. Includes most in/equalities and fuzzy matching options(i.e., leading/trailing `*` )
#
# Example syntax:  `status=open&time>2001-1-1&name=*Bar`
#
# Example use and definition of the type:
# attribute :filters,
#           Types::FilteringParams.for(MediaTypes::MyType) do
#   filter 'user.id', using: ['=', '!=']
#   filter 'name', using: ['=', '!=', '!', '!!]
#   filter 'children.created_at', using: ['>', '>=', '<', '<=']
#   filter 'display_name', using: ['=', '!='], fuzzy: true
# end

module Praxis
  module Extensions
    module AttributeFiltering
      class FilteringParams
        include Attributor::Type
        include Attributor::Dumpable
  
        attr_reader :parsed_array

        class DSLCompiler < Attributor::DSLCompiler
          # "account.id": { operators: ["=", "!="] },
          # name:         { operators: ["=", "!="], fuzzy_match: true },
          # start_date:   { operators: ["!=", ">=", "<=", "=", "<", ">"] }
          #
          def filter(name, using: nil, fuzzy: false)
            target.add_filter(name.to_sym, operators: Set.new(using), fuzzy: fuzzy)
          end
        end
  
        VALUE_OPERATORS = Set.new(['!=', '>=', '<=', '=', '<', '>']).freeze
        NOVALUE_OPERATORS = Set.new(['!','!!']).freeze
        AVAILABLE_OPERATORS = Set.new(VALUE_OPERATORS+NOVALUE_OPERATORS).freeze
  
        # Abstract class, which needs to be used by subclassing it through the .for method, to set the allowed filters
        # definition should be a hash, keyed by field name, which contains a hash that can have two pieces of metadata
        # :operators => an array of operators allowed (if empty, means all)
        # :value_type => a type class which the value should match
        # :fuzzy_match => weather or not we allow a "like" type query (for prefix or suffix matching)
        class << self
          attr_reader :media_type
          attr_reader :allowed_filters
  
          def for(media_type, **_opts)
            unless media_type < Praxis::MediaType
              raise ArgumentError, "Invalid type: #{media_type.name} for Filters. " \
                'Using the .for method for defining a filter, requires passing a subclass of a MediaType'
            end
  
            ::Class.new(self) do
              @media_type = media_type
              @allowed_filters = {}
            end
          end
  
          def json_schema_type
            :string
          end
      
          def add_filter(name, operators:, fuzzy:)
            components = name.to_s.split('.').map(&:to_sym)
            attribute, enclosing_type = find_filter_attribute(components, media_type)
            raise 'Invalid set of operators passed' unless AVAILABLE_OPERATORS.superset?(operators)
  
            @allowed_filters[name] = {
              value_type: attribute.type,
              operators: operators,
              fuzzy_match: fuzzy
            }
          end
        end
    
        def self.native_type
          self
        end
  
        def self.name
          'Praxis::Types::FilteringParams'
        end
  
        def self.display_name
          'Filtering'
        end
  
        def self.family
          'string'
        end
  
        def self.constructable?
          true
        end
  
        def self.construct(definition, **options)
          return self if definition.nil?
  
          DSLCompiler.new(self, **options).parse(*definition)
          self
        end
  
        def self.find_filter_attribute(name_components, type)
          type = type.member_type if type < Attributor::Collection
          first, *rest = name_components
          first_attr = type.attributes[first]
          unless first_attr
            raise "Error, you've requested to filter by field #{first} which does not exist in the #{type.name} mediatype!\n"
          end
  
          return find_filter_attribute(rest, first_attr.type) if rest.present?
  
          [first_attr, type] # Return the attribute and associated enclosing type
        end
  
        def self.example(_context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
          fields = if media_type
                     mt_example = media_type.example
                     pickable_fields = mt_example.object.keys & allowed_filters.keys
                     pickable_fields.sample(2).each_with_object([]) do |filter_name, arr|
                       op = allowed_filters[filter_name][:operators].to_a.sample(1).first
  
                       # Switch this to pick the right example attribute from the mt example
                       filter_components = filter_name.to_s.split('.').map(&:to_sym)
                       mapped_attribute, _enclosing_type = find_filter_attribute(filter_components, media_type)
                       unless mapped_attribute
                         raise "filter with name #{filter_name} does not correspond to an existing field inside " \
                               " MediaType #{media_type.name}"
                       end
                       if NOVALUE_OPERATORS.include?(op)
                        arr << "#{filter_name}#{op}" # Do not add a value for the operators that don't take it
                       else
                        attr_example = filter_components.inject(mt_example) do |last, name|
                          # we can safely do sends, since we've verified the components are valid
                          last.send(name)
                        end
                        arr << "#{filter_name}#{op}#{attr_example}"
                      end
                     end.join('&')
                   else
                     'name=Joe&date>2017-01-01'
                   end
          load(fields)
        end
  
        def self.validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
          instance = load(value, context)
          instance.validate(context)
        end
  
        def self.load(filters, _context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
          return filters if filters.is_a?(native_type)
          return new if filters.nil? || filters.blank?

          parsed = Parser.new.parse(filters)
          
          tree = ConditionGroup.load(parsed)

          rr = tree.flattened_conditions
          accum = []
          rr.each do |spec|
            attr_name = spec[:name]
            # TODO: Do we need to CGI.unescape things? here or even before??...
            coerced = \
              if media_type
                filter_components = attr_name.to_s.split('.').map(&:to_sym)
                attr, _enclosing_type = find_filter_attribute(filter_components, media_type)
                if spec[:values].is_a?(Array)
                  attr_coll = Attributor::Collection.of(attr.type)
                  attr_coll.load(spec[:values])
                else
                  attr.load(spec[:values])
                end
              else
                spec[:values]
              end
            accum.push(name: attr_name, op: spec[:op], value: coerced , node_object: spec[:node_object])
          end
          new(accum)
        end
  
        def self.dump(value, **_opts)
          load(value).dump
        end
  
        def self.describe(_root = false, example: nil)
          hash = super
          if allowed_filters
            hash[:filters] = allowed_filters.each_with_object({}) do |(name, spec), accum|
              accum[name] = { operators: spec[:operators].to_a }
              accum[name][:fuzzy] = true if spec[:fuzzy_match]
            end
          end
  
          hash
        end
  
        def initialize(parsed = [])
          @parsed_array = parsed
        end
  
        def validate(_context = Attributor::DEFAULT_ROOT_CONTEXT)
          parsed_array.each_with_object([]) do |item, errors|
            attr_name = item[:name]
            attr_filters = allowed_filters[attr_name]
            unless attr_filters
              errors << "Filtering by #{attr_name} is not allowed. You can filter by #{allowed_filters.keys.map(&:to_s).join(', ')}"
              next
            end
            allowed_operators = attr_filters[:operators]
            unless allowed_operators.include?(item[:op])
              errors << "Operator #{item[:op]} not allowed for filter #{attr_name}"
            end
            value_type = attr_filters[:value_type]
            next unless value_type == Attributor::String

            value = item[:value]
            unless value.empty?
              fuzzy_match = attr_filters[:fuzzy_match]
              if (value[-1] == '*' || value[0] == '*') && !fuzzy_match
                errors << "Fuzzy matching for #{attr_name} is not allowed (yet '*' was found in the value)"
              end
            end
          end
        end
  
        # Dump back string parseable form
        def dump
          parsed_array.each_with_object([]) do |item, arr|
            field = item[:name]
            arr << "#{field}#{item[:op]}#{item[:value]}"
          end.join('&')
        end
  
        def each
          parsed_array&.each do |filter|
            yield filter
          end
        end
  
        def allowed_filters
          # Class method defined by the subclassing Class (using .for)
          self.class.allowed_filters
        end
      end
    end
  end
end

# Alias it to a much shorter and sweeter name in the Types namespace.
module Praxis
  module Types
    FilteringParams = Praxis::Extensions::AttributeFiltering::FilteringParams
  end
end

# rubocop:enable all
