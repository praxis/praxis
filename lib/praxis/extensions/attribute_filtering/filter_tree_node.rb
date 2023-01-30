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
            # Need to only get the path to the attribute, but without it
            # For null or not null associations, there is no attribute name in the filter already
            relation_path = \
              if ['!', '!!'].include?(cond[:op])
                cond[:orig_name].to_s
              else
                cond[:orig_name].to_s.split('.')[0..-2].join('.')
              end
            accum[relation_path] = path unless relation_path.empty?
          }
          children.each do |(name,node)|
            innerdump(node.conditions, node.children, path + [name], accum)
          end
          accum
        end
        # def self.innerdump(conditions, children, path, accum)
        #   prefix = path == [''] ? [] : path # Delete empty string component path if that's how it arrives here
        #   conditions.each{ |cond| 
        #     accum[(prefix + [cond[:name]]).join('.')] = prefix
        #   }
        #   children.each do |(name,node)|
        #     innerdump(node.conditions, node.children, path + [name], accum)
        #   end
        #   accum
        # end
      end
    end
  end
end
