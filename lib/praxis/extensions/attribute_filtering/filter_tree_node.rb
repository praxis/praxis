module Praxis
  module Extensions
    module AttributeFiltering
      class FilterTreeNode
        attr_reader :path, :conditions, :children
        # Parsed_filters is an Array of {name: X, op: Y, value: Z} ... exactly the format of the FilteringParams.load method
        # It can also contain a :node_object
        def initialize(parsed_filters, path: [])
          @path = path # Array that marks the tree 'path' to this node (with respect to the absolute root)
          @conditions = [] # Conditions to apply directly to this node
          @children = {} # Hash with a new NodeTree object value, keyed by name
          children_data = {} # Hash with keys as names of the first level component of the children nodes (and values as array of matching filters)
          parsed_filters.map do |hash|
            *components = hash[:name].to_s.split('.')
            if components.empty?
              return
            elsif components.size == 1
              @conditions << hash.slice(:name, :op, :value, :fuzzy, :node_object)
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
            hash[name] = self.class.new(sub_filters, path: path + [name] )
          end
        end
      end
    end
  end
end