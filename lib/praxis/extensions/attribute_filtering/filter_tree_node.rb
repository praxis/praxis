# frozen_string_literal: true

module Praxis
  module Extensions
    module AttributeFiltering
      class FilterTreeNode
        attr_reader :path, :conditions, :children

        # Parsed_filters is an Array of {name: X, op: Y, value: Z} ... exactly the format of the FilteringParams.load method
        # It can also contain a :node_object and an :orig_name (that indicates the original name of the attribute before the mapping, if different)
        def initialize(parsed_filters, path: [])
          @path = path # Array that marks the tree 'path' to this node (with respect to the absolute root)
          @conditions = [] # Conditions to apply directly to this node
          @children = {} # Hash with a new NodeTree object value, keyed by name
          children_data = {} # Hash with keys as names of the first level component of the children nodes (and values as array of matching filters)
          parsed_filters.map do |hash|
            *components = hash[:name].to_s.split('.')
            next if components.empty?

            if components.size == 1
              @conditions << hash.slice(:name, :op, :value, :fuzzy, :node_object, :orig_name)
            else
              children_data[components.first] ||= []
              children_data[components.first] << hash
            end
          end
          # An array of FilterTreeNodes corresponding to each children
          @children = children_data.each_with_object({}) do |(name, arr), hash|
            sub_filters = arr.map do |item|
              _parent, *rest = item[:name].to_s.split('.')
              # NOTE: The orig_name becomes untouched, so it has the FULL PATH of the original name...unless the name, that we're scoping to the path
              item.merge(name: rest.join('.'))
            end
            hash[name] = self.class.new(sub_filters, path: path + [name])
          end
        end

        # Dump the mapping of a filter dotted string, to the resulting path
        # This can be used by other parts (i.e., sorting functions) to know which filters map to which aliases
        def dump_mappings
          self.class.innerdump(conditions, children, path, {})
        end

        def self.innerdump(conditions, children, path, accum)
          conditions.each{ |cond|
            # Skip dumping the filters that have no leaf value (! and !! operators) and they're special and do not really have a single value to order/compare by
            accum[cond[:orig_name].to_s] = path unless ['!', '!!'].include?(cond[:op])
          }
          children.each do |(name,node)|
            innerdump(node.conditions, node.children, path + [name], accum)
          end
          accum
        end
      end
    end
  end
end
