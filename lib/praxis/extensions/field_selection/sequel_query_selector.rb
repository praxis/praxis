# frozen_string_literal: true

require 'sequel'

module Praxis
  module Extensions
    module FieldSelection
      class SequelQuerySelector
        attr_reader :selector, :query
        # Gets a dataset, a selector...and should return a dataset with the selector definition applied.
        def initialize(query:, selectors:)
          @selector = selectors
          @query = query
        end

        def generate(debug: false)
          @query = add_select(query: query, selector_node: @selector)
          
          @query = @selector.tracks.inject(@query) do |ds, (track_name, track_node)|
            ds.eager(track_name => _eager(track_node) )
          end

          explain_query(query) if debug
          @query
        end

        def _eager(selector_node)
          lambda do |dset|
            dset = add_select(query: dset, selector_node: selector_node)

            dset = selector_node.tracks.inject(dset) do |ds, (track_name, track_node)|
              ds.eager(track_name => _eager(track_node) )
            end

          end
        end

        def add_select(query:, selector_node:)
          # We're gonna always require the PK of the model, as it is a special case for Sequel, and the app itself 
          # might assume it is always there and not be surprised by the fact that if it isn't, it won't blow up
          # in the same way as any other attribute not being loaded...i.e., NoMethodError: undefined method `foobar' for #<...>
          select_fields = selector_node.select + [selector_node.resource.model.primary_key.to_sym]
    
          table_name = selector_node.resource.model.table_name
          qualified = select_fields.map { |f| Sequel.qualify(table_name, f) }
          query.select(*qualified)
        end

        def explain_query(ds)
          prev_loggers = Sequel::Model.db.loggers
          stdout_logger = Logger.new($stdout)
          Sequel::Model.db.loggers = [stdout_logger]
          stdout_logger.debug("Query plan for ...#{selector.resource.model} with selectors: #{JSON.generate(selector.dump)}")
          ds.all
          stdout_logger.debug("Query plan end")
          Sequel::Model.db.loggers = prev_loggers
        end
      end
    end
  end
end