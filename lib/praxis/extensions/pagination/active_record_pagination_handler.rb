# frozen_string_literal: true

require_relative 'pagination_handler'

module Praxis
  module Extensions
    module Pagination
      class ActiveRecordPaginationHandler < PaginationHandler
        def self.where_lt(query, attr, value)
          # TODO: common for AR/Sequel? Seems we could use Arel and more-specific Sequel things
          query.where(query.table[attr].lt(value))
        end

        def self.where_gt(query, attr, value)
          query.where(query.table[attr].gt(value))
        end

        def self.order(query, order, root_resource:)
          return query unless order

          query = query.reorder('')
          order.each do |spec_hash|
            direction, string = spec_hash.first
            resource, mapped_name = _locate_pair(root_resource, string.to_s.split('.').map(&:to_sym))
            # NOTE: We are simply using the direct table name of the inner joined field
            # if there are multiple preloaded tables in the query, we might be using the
            # wrong name/alias if we were meant to order by that other one...
            # The complexity of having to figure that out in AR (with how messy the alias
            # are handled) with the low likelyhood of these cases happenning is screaming
            # to leave it as is...and wait to see if this is something we really want to fix later on
            query = query.references(resource.model.table_name.to_sym) # Ensure we join the table we're sorting by...
            query = query.order("#{resource.model.table_name}.#{mapped_name}" => direction)
          end
          query
        end

        def self.count(query)
          query.count(:all)
        end

        def self.offset(query, offset)
          query.offset(offset)
        end

        def self.limit(query, limit)
          query.limit(limit)
        end

        # Based off of a root resource and an incoming path of dot-separated attributes...
        # find the leaf attribute and its associated resource (including mapping names of associations/attributes along the way)
        # as defined by the `order_mapping` stanzas of resources
        def self._locate_pair(resource, path)
          main, rest = path
          mapped_name = resource.order_mapping[main] || main

          association = resource.model._praxis_associations[mapped_name.to_sym]
          if association
            related_resource = resource.model_map[association[:model]]
            _locate_pair(related_resource, rest)
          elsif !rest.presence
            # Assume it is just a column name
            [resource, mapped_name]
          else
            # Could not find an association and there are more components to cover...something's not right
            raise 'Error trying to map ordering components to the order_mapping of the resources. ' \
                  "Could not find a mapping for property: #{mapped_name} in resource #{resource.name}. Did you forget to add a mapping for it in the `order_mapping` stanza ?"
          end
        end
      end
    end
  end
end
