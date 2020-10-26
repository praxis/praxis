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

        def self.order(query, order)
          return query unless order
          query = query.reorder('')
          
          order.each do |spec_hash|
            direction, name = spec_hash.first
            query = query.order(name => direction)
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
      end
    end
  end
end
