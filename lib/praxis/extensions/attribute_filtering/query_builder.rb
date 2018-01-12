# frozen_string_literal: true
require_relative 'active_record_filter_query_builder'

module Praxis
  module Extensions
    module QueryBuilder
    # To include in a resource object...
      extend ActiveSupport::Concern

      included do
        # TODO: this shouldn't be needed if we incorporate it with the properties of the mapper...
        def self.filters_mapping(hash)
          @query_builder_class = ActiveRecordFilterQueryBuilder.for(**hash)
        end
        
        def self.query_builder_class
          @query_builder_class
        end

        def self.craft_query(base_query, filters) # rubocop:disable Metrics/AbcSize
          # Assume QueryBuilder
          if query_builder_class
            unless query_builder_class.ancestors.include?(ActiveRecordFilterQueryBuilder)
              raise ArgumentError, ':query_builder_class must a class extending FilterQueryBuilder'
            end

            if filters && query_builder_class
              base_query = query_builder_class.new(query: base_query, model: model ).build_clause(filters)
            end
            # puts "FILTERS_QUERY: #{filters_query.sql}"
          end
          
          base_query
        end
      end

    end
  end
end