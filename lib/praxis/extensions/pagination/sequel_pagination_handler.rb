# frozen_string_literal: true
require_relative 'pagination_handler'

module Praxis
  module Extensions
    module Pagination
      class SequelPaginationHandler < PaginationHandler
        def self.where_lt(query, attr, value)
          query.where("#{attr} < ?", value)
        end

        def self.where_gt(query, attr, value)
          query.where("#{attr} > ?", value)
        end

        def self.order(query, order)
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
          query.order(*order_clause)
        end

        def self.count(query)
          query.count
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
