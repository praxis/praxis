# frozen_string_literal: true
module Praxis
  module Extensions
    module FieldSelection
      class ActiveRecordQuerySelector
        attr_reader :selector, :query, :top_model, :resolved, :root
        # Gets a dataset, a selector...and should return a dataset with the selector definition applied.
        def initialize(query:, model:, selectors:, resolved:)
          @selector = selectors
          @query = query
          @top_model = model
          @resolved = resolved
          @seen = Set.new
          @root = model.table_name
        end

        def add_select(query:, model:, table_name:)
          if (fields = fields_for(model))
            # Note, let's always add the pk fields so that associations can load properly
            fields = fields | [model.primary_key.to_sym]
            query.select(*fields)
          else
            query
          end
        end

        def generate
          # TODO: unfortunately, I think we can only control the select clauses for the top model 
          # (as I'm not sure ActiveRecord supports expressing it in the join...)
          @query = add_select(query: query, model: top_model, table_name: root)

          @query.includes(_eager(top_model, resolved) )
        end

        def _eager(model, resolved)
          tracks = only_assoc_for(model, resolved)
          tracks.inject([]) do |dataset, track|
            next dataset if @seen.include?([model, track])
            @seen << [model, track]
            assoc_model = model._praxis_associations[track][:model]
            dataset << { track => _eager(assoc_model, resolved[track]) }
          end
        end

        def only_assoc_for(model, hash)
          hash.keys.reject { |assoc| model._praxis_associations[assoc].nil? }
        end

        def fields_for(model)
          selector[model][:select].to_a
        end
      end
    end
  end
end