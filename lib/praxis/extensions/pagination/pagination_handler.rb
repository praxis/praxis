module Praxis
  module Extensions
    module Pagination
      class PaginationHandler
        class PaginationException < Exception; end

        def self.paginate(query, table, pagination)
          # TODO: rethink how/if table is necessary for AR/Sequel...
          return query unless pagination.paginator

          paginator = pagination.paginator

          q = if paginator.page
            #query.offset((paginator.page - 1) * paginator.items)
            offset(query, (paginator.page - 1) * paginator.items)            
          else
            # TODO: this table concept might be for AR? not for Sequel?...
            attr_selector = (table ? "#{table}.#{paginator.by}" : paginator.by)

            # If there is an order clause that complies with the "by" field sorting, we can use it directly
            # i.e., We can be smart about allowing the main sort field matching the pagination one (in case you want to sub-order in a custom way)
            oclause = if pagination.order.nil? || pagination.order.empty? # No ordering specified => use ascending based on the "by" field
                        direction = :asc
                        order(query, [{ asc: attr_selector }])
                      else
                        first_ordering = pagination.order.items.first
                        direction = first_ordering.keys.first
                        unless first_ordering[direction].to_sym == pagination.paginator.by.to_sym
                          string_clause = pagination.order.items.map { |h|
                            dir, name = h.first
                            "#{name} #{dir}"
                          }.join(',')
                          # FIXME: What to return here?
                          raise PaginationException,
                                "Ordering clause [#{string_clause}] is incompatible with pagination by field '#{pagination.paginator.by}'. " \
                                "When paginating by a field value, one cannot specify the 'order' clause " \
                                "unless the clause's primary field matches the pagination field."
                        end
                        order(query, pagination.order)
                      end

            if paginator.from
              if direction == :desc
                where_lt(oclause, attr_selector, paginator.from)
              else
                where_gt(oclause, attr_selector, paginator.from)
              end
            else
              oclause
            end

          end
          limit(q, paginator.items)
        end

        def self.where_lt(query, attr, value)
          # TODO: common for AR/Sequel? Seems we could use Arel and more-specific Sequel things
          # query.where(query.table[attr].lt(value))  TODO   Use this (when fixed)
          query.where("#{attr} < ?", value)
        end
        
        def self.where_gt(query, attr, value)
          #query.where(query.table[attr].gt(value)) TODO    Use this (when fixed)
          query.where("#{attr} > ?", value)
        end

        def self.offset(query, offset)
          # TODO: common for AR/Sequel
          query.offset(offset)
        end

        def self.limit(query, limit)
          # TODO: common for AR/Sequel
          query.limit(limit)
        end

        def self.order(query, order)
          # TODO: hardcoding
          activerecord_order(query,order)
        end
        
        def self.count(query)
          # TODO: hardcoding
          activerecord_count(query)
        end

        ####################################

        def self.activerecord_count(query)
          query.count(:all)
        end

        def self.sequel_count(query)
          query.count
        end

        def self.sequel_order(query, order)
          return query unless order
          order_clause = order.map do |spec_hash|
            direction, name = spec_hash.first
            case direction.to_sym
            when :desc
              Sequel.desc(name.to_sym)
            else
              Sequel.asc(name.to_sym)
            end
          end
          query = query.order(*order_clause)
          query
        end

        def self.activerecord_order(query, order)
          return query unless order
          query = query.reorder('')
          
          order.each do |spec_hash|
            direction, name = spec_hash.first
            query = query.order(name => direction)
          end
          query
        end
        
      end
    end
  end
end
