require 'praxis/extensions/attribute_filtering/filtering_params'
require 'praxis/extensions/attribute_filtering/filter_tree_node'
module Praxis
  module Extensions
    module AttributeFiltering
      class MultiMatchWithFuzzyNotAllowedByAdapter < StandardError
        def initialize
          msg = 'Matching multiple, comma-separated values with fuzzy matches for a single field is not allowed by this DB adapter'\
                'Please use multiple OR clauses instead.'
          super(msg)
        end
      end
    end
  end
end
