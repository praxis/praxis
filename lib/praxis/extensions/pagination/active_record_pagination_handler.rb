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

        def self.order(query, order, root_resource:, filter_builder: )
          return query unless order

          query = query.reorder('')
          order.each do |spec_hash|
            direction, string = spec_hash.first
            string_components = string.to_s.split('.')
            resource, mapped_name = _locate_pair(root_resource, string_components.map(&:to_sym))

            # Check if the 'path' (without the final column name) is something we have in our filters already
            # and if so, get the alias we've assigned to it as a way to reference that directly
            path_without_column = string_components[0..-2].join('.')
            table_alias = filter_builder.resulting_filter_aliases[path_without_column]

            # If we don't have used the 'path' already for a filter alias, we'll default to the simple table name
            # NOTE: if we haven't used an alias from the filters, this might be incorrect!
            # That is because if the total query had more than one of that same preloaded table, AR will select
            # it own alias and we might be using the wrong one if we were meant to order by that other one...
            # The complexity of having to figure that out in AR (with how messy the alias
            # are handled) with the low likelyhood of these cases happenning is screaming
            # to leave it as is...and wait to see if this is something we really want to fix later on
            prefix = table_alias || resource.model.table_name

            quoted_prefix = quote_column_path(query: query, prefix: prefix, column_name: mapped_name)
            order_clause = ActiveRecord::Base.sanitize_sql_array("#{quoted_prefix} #{direction}")

            # TODO: Do we need to ensure we have a 'reference' to that table so that AR preloads it?
            # query = query.references(prefix.to_sym) TODO: need to build the right object...a symbol might not do for references
            query = query.order(Arel.sql(order_clause))
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

        def self.quote_column_path(query:, prefix:, column_name:)
          c = query.connection
          quoted_column = c.quote_column_name(column_name)
          if prefix
            quoted_table = c.quote_table_name(prefix)
            "#{quoted_table}.#{quoted_column}"
          else
            quoted_column
          end
        end

        # Based off of a root resource and an incoming path of dot-separated attributes...
        # find the leaf attribute and its associated resource (including mapping names of associations/attributes along the way)
        # as defined by the `order_mapping` stanzas of resources
        def self._locate_pair(resource, path)
          main, *rest = path
          mapped_name = resource.order_mapping[main.to_sym] || main

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
