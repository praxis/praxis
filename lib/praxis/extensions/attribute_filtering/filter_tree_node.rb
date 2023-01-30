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

        def aliases_by_association
          self.class.aliases_by_association(conditions, children, path, {})
        end

        # Returns a hash that maps the used associations from the filter conditions (i.e., original filter names without the final leaf)
        # ...to the chosen alias for it (in the form of an array of components)
        # For example: ORIG NAMES => translated assocs in an ordered array
        # Filters for 'origrel1.origrel2.attribute_name=Foobar'
        # {
        #   'origrel1.origrel2' => ['rel1', 'rel2'],
        # }
        # assuming that the relationship names from the orig* names, have been filter_mapped to 'rel1' and 'rel2' respectively
        # Note: the ! operators also exist in the map, despite having no leaf condition, obviously
        # This is used in the sorting code to match a given sort string, to which aliased path to map it to.
        def self.aliases_by_association(conditions, children, path, accum)
          conditions.each{ |cond|
            if ['!', '!!'].include?(cond[:op])
              orig_assoc = cond[:orig_name]
              assoc_path = path + [cond[:name]]
            else
              orig_assoc = cond[:orig_name].to_s.split('.')[0..-2].join('.')
              assoc_path = path.dup
            end

            # Skip dumping the filters that have no leaf value (! and !! operators) and they're special and do not really have a single value to order/compare by
            accum[orig_assoc] = assoc_path unless orig_assoc.empty?
          }
          children.each do |(name,node)|
            aliases_by_association(node.conditions, node.children, path + [name], accum)
          end
          accum
        end
      end
    end
  end
end
