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
            info = association_info_for(root_resource, string.to_s.split('.'))

            # Convert the includes path (it is not a tree), to a column prefix
            pointer = info[:includes]
            dotted = []
            loop do
              break if pointer.empty?

              key, subhash = pointer.first
              dotted.push(key)
              pointer = subhash
            end
            column_prefix = dotted.empty? ? root_resource.model.table_name : ([''] + dotted).join(AttributeFiltering::ActiveRecordFilterQueryBuilder::REFERENCES_STRING_SEPARATOR)

            # If the sorting refers to a deeper association, make sure to add the join and the special reference
            if column_prefix
              refval = AttributeFiltering::ActiveRecordFilterQueryBuilder.build_reference_value(column_prefix, query: query)
              # Outter join hash needs to be a string based hash format!! (if it's in symbols, it won't match it and we'll cause extra joins)
              query = query.left_outer_joins(info[:includes]).references(refval)
            end

            quoted_prefix = AttributeFiltering::ActiveRecordFilterQueryBuilder.quote_column_path(query: query, prefix: column_prefix, column_name: info[:attribute])
            order_clause = Arel.sql(ActiveRecord::Base.sanitize_sql_array("#{quoted_prefix} #{direction}"))
            query = query.order(order_clause)
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
        # as defined by the `order_mapping` stanzas of resources:
        # resource: final resource the attribute is associated with
        # includes: a hash in the shape of AR includes, where keys are strings (that is very important)
        # column_name: final attribute name where this path leads to. Nil if the path ends at an association
        def self.association_info_for(resource, path)
          main, *rest = path
          mapped_name = resource.order_mapping[main.to_sym] || main

          if (association = resource.model.reflections[mapped_name])
            related_resource = resource.model_map[association.klass]
            if rest.presence
              result = association_info_for(related_resource, rest)
              { resource: result[:resource], includes: { mapped_name => result[:includes]}, attribute: result[:attribute] }
            else # Ends with an association (i.e., for ! or !! attributes)
              { resource: related_resource, includes: { mapped_name => {} }, attribute: nil }
            end
          elsif !rest.presence
            # Since it is not an association, must be a column name
            { resource: resource, includes: {}, attribute: mapped_name }
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
