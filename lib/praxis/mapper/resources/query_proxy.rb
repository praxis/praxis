# frozen_string_literal: true

module Praxis
  module Mapper
    module Resources
      class QueryProxy
        attr_reader :klass

        def initialize(klass:)
          @klass = klass
        end

        def including(includes)
          @_includes = includes
          self
        end

        # Can pass extra includes through :_includes
        # TODO: We should not use the AR includes, but first pass them through the properties, cause
        #  we need to expand based on the resource methods, not the model methods
        def get(condition)
          base = klass.model._add_includes(klass.model, @_includes) # includes(nil) seems to have no effect
          record = base._get(condition)

          record.nil? ? nil : klass.for_record(record)
        end

        def get!(condition)
          resource = get(condition)
          # TODO: passing the :id if there is one in the condition...but can be more complex...think if we want to expose more
          raise Praxis::Mapper::ResourceNotFound.new(type: @klass, id: condition[:id]) unless resource

          resource
        end

        # Retrieve all or many wrapped resources
        # .all -> returns them all
        # .all(name: 'foo') -> returns all that match the name
        def all(condition = {})
          base = klass.model._add_includes(klass.model, @_includes) # includes(nil) seems to have no effect
          records = base._all(condition)

          klass.wrap(records)
        end

        def first
          record = klass.model._first
          record.nil? ? nil : klass.wrap(record)
        end

        def last
          record = klass.model._last
          record.nil? ? nil : klass.wrap(record)
        end
      end
    end
  end
end
