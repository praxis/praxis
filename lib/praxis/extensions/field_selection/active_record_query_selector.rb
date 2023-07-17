# frozen_string_literal: true

module Praxis
  module Extensions
    module FieldSelection
      class ActiveRecordQuerySelector
        attr_reader :selector, :query

        # Gets a dataset, a selector...and should return a dataset with the selector definition applied.
        def initialize(query:, selectors:, debug: false)
          @selector = selectors
          @query = query
          @logger = debug ? Logger.new($stdout) : nil
        end

        def generate
          # TODO: unfortunately, I think we can only control the select clauses for the top model
          # (as I'm not sure ActiveRecord supports expressing it in the join...)
          @query = add_select(query: query, selector_node: selector)
          eager_hash = _eager(selector)

          @query = @query.includes(eager_hash)
          explain_query(query, eager_hash) if @logger

          @query
        end

        def add_select(query:, selector_node:)
          # We're gonna always require the PK of the model, as it is a special case for AR, and the app itself
          # might assume it is always there and not be surprised by the fact that if it isn't, it won't blow up
          # in the same way as any other attribute not being loaded...i.e., ActiveModel::MissingAttributeError: missing attribute: xyz
          select_fields =
            _hoist_select(
              selector_node: selector_node,
              fields_closure:
                Set.new([selector_node.resource.model.primary_key.to_sym]),
            ).to_a
          select_fields.empty? ? query : query.select(*select_fields)
        end

        def explain_query(query, eager_hash)
          @logger.debug(
            "Query plan for ...#{selector.resource.model} with selectors: #{JSON.generate(selector.dump)}",
          )
          @logger.debug(
            " ActiveRecord query: #{selector.resource.model}.includes(#{eager_hash})",
          )
          query.explain
          @logger.debug('Query plan end')
        end

        private

        def _eager(selector_node)
          selector_node.tracks.transform_values do |track_node|
            _eager(track_node)
          end
        end

        # This deals with a performance optimization introduced in ActiveRecord 7
        # When preloading associations, they now reuse model instances that have already
        # been loaded as part of the same chain of queries.
        #
        # If the root uses a `select` constraint, then some attributes may not be loaded
        # if the record is reused elsewhere in the resulting graph of models. In former
        # versions of ActiveRecord, a `SELECT *` would have been used to instantiate these
        # nested versions of the model and so all attributes would have been loaded.
        #
        # To account for this discrepancy, we hoist all transitive columns of the root
        # model up to the root of the query tree, preserving the optimization benefit
        # of a narrow field selector while ensuring that all requested fields are
        # available at every node in the model graph.
        #
        # @return [Set<Symbol]
        def _hoist_select(root_node: nil, selector_node:, fields_closure:)
          root_node ||= selector_node
          if root_node.resource == selector_node.resource
            fields_closure.merge(selector_node.select)
          end
          selector_node.tracks.values.each do |track_node|
            _hoist_select(
              root_node: root_node,
              selector_node: track_node,
              fields_closure: fields_closure,
            )
          end
          fields_closure
        end
      end
    end
  end
end
