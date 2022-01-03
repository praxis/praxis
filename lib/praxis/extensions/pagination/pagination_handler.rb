# frozen_string_literal: true

module Praxis
  module Extensions
    module Pagination
      class PaginationHandler
        class PaginationException < RuntimeError; end

        def self.paginate(query, pagination)
          return query unless pagination.paginator

          paginator = pagination.paginator

          q = if paginator.page
                offset(query, (paginator.page - 1) * paginator.items)
              else
                # If there is an order clause that complies with the "by" field sorting, we can use it directly
                # i.e., We can be smart about allowing the main sort field matching the pagination one (in case you want to sub-order in a custom way)
                oclause = if pagination.order.nil? || pagination.order.empty? # No ordering specified => use ascending based on the "by" field
                            direction = :asc
                            order(query, [{ asc: paginator.by }])
                          else
                            first_ordering = pagination.order.items.first
                            direction = first_ordering.keys.first
                            unless first_ordering[direction].to_sym == pagination.paginator.by.to_sym
                              string_clause = pagination.order.items.map do |h|
                                dir, name = h.first
                                "#{name} #{dir}"
                              end.join(',')
                              raise PaginationException,
                                    "Ordering clause [#{string_clause}] is incompatible with pagination by field '#{pagination.paginator.by}'. " \
                                    "When paginating by a field value, one cannot specify the 'order' clause " \
                                    "unless the clause's primary field matches the pagination field."
                            end
                            order(query, pagination.order)
                          end

                if paginator.from
                  if direction == :desc
                    where_lt(oclause, paginator.by, paginator.from)
                  else
                    where_gt(oclause, paginator.by, paginator.from)
                  end
                else
                  oclause
                end

              end
          limit(q, paginator.items)
        end

        def self.where_lt(_query, _attr, _value)
          raise 'implement in derived class'
        end

        def self.where_gt(_query, _attr, _value)
          raise 'implement in derived class'
        end

        def self.offset(_query, _offset)
          raise 'implement in derived class'
        end

        def self.limit(_query, _limit)
          raise 'implement in derived class'
        end
      end
    end
  end
end
