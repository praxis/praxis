# frozen_string_literal: true
module Praxis
  module Extensions
    module FieldSelection
      class SequelQuerySelector
        attr_reader :selector, :ds, :top_model, :resolved, :root
        # Gets a dataset, a selector...and should return a dataset with the selector definition applied.
        def initialize(ds:, model:, selectors:, resolved:)
          @selector = selectors
          @ds = ds
          @top_model = model
          @resolved = resolved
          @seen = Set.new
          @root = model.table_name
        end

        def add_select(ds:, model:, table_name:)
          if (fields = fields_for(model))
            # Note, let's always add the pk fields so that associations can load properly
            fields = fields | model.primary_key | [:id]
            qualified = fields.map { |f| Sequel.qualify(table_name, f) }
            ds.select(*qualified)
          else
            ds
          end
        end

        def generate
          @ds = add_select(ds: ds, model: top_model, table_name: root)

          tracks = only_assoc_for(top_model, resolved)
          @ds = tracks.inject(@ds) do |dataset, track|
            next dataset if @seen.include?([top_model, track])
            @seen << [top_model, track]
            assoc_model = top_model.associations[track][:model]
            #      hash[track] = _eager(assoc_model, resolved[track])
            dataset.eager(track => _eager(assoc_model, resolved[track]))
          end
        end

        def _eager(model, resolved)
          lambda do |dset|
            d = add_select(ds: dset, model: model, table_name: model.table_name)

            tracks = only_assoc_for(model, resolved)
            tracks.inject(d) do |dataset, track|
              next dataset if @seen.include?([model, track])
              @seen << [model, track]
              assoc_model = model.associations[track][:model]
              dataset.eager(track => _eager(assoc_model, resolved[track]))
            end
          end
        end

        def only_assoc_for(model, hash)
          hash.keys.reject { |assoc| model.associations[assoc].nil? }
        end

        def fields_for(model)
          selector[model][:select].to_a
        end
      end
    end
  end
end