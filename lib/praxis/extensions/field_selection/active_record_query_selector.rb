# frozen_string_literal: true
module Praxis
  module Extensions
    module FieldSelection
      class ActiveRecordQuerySelector
        attr_reader :selector, :query
        # Gets a dataset, a selector...and should return a dataset with the selector definition applied.
        def initialize(query:, selectors:)
          @selector = selectors
          @query = query
        end

        def generate(debug: false)
          # TODO: unfortunately, I think we can only control the select clauses for the top model 
          # (as I'm not sure ActiveRecord supports expressing it in the join...)
          @query = add_select(query: query, selector_node: selector)
          eager_hash = _eager(selector)

          @query = @query.includes(eager_hash)          
          explain_query(query, eager_hash) if debug

          @query
        end

        def add_select(query:, selector_node:)
          # We're gonna always require the PK of the model, as it is a special case for AR, and the app itself 
          # might assume it is always there and not be surprised by the fact that if it isn't, it won't blow up
          # in the same way as any other attribute not being loaded...i.e., ActiveModel::MissingAttributeError: missing attribute: xyz
          select_fields = selector_node.select + [selector_node.resource.model.primary_key.to_sym]
          select_fields.empty? ? query : query.select(*select_fields)
        end

        def _eager(selector_node)
          selector_node.tracks.each_with_object({}) do |(track_name, track_node), h|
            h[track_name] = _eager(track_node)
          end
        end

        def explain_query(query, eager_hash)
          prev = ActiveRecord::Base.logger
          ActiveRecord::Base.logger = Logger.new(STDOUT)
          ActiveRecord::Base.logger.debug("Query plan for ...#{selector.resource.model} with selectors: #{JSON.generate(selector.dump)}")
          ActiveRecord::Base.logger.debug(" ActiveRecord query: #{selector.resource.model}.includes(#{eager_hash})")
          query.explain
          ActiveRecord::Base.logger.debug("Query plan end")
          # TODO!!!! make sure we do not set it to "nil" as this is a singleton that can be change by other threads...
          # TODO ... maybe rethink the setting of logger and just spit it out to whatever the logger is...or just to it to STDOUT
          ActiveRecord::Base.logger = prev
        end
      end
    end
  end
end