# frozen_string_literal: true

module Praxis
  module Mapper
    module QueryMethods
      extend ::ActiveSupport::Concern

      # Includes some limited, but handy query methods so we can transparently
      # use them from the resource layer, and get wrapped resources from it
      module ClassMethods
        def including(args)
          Praxis::Mapper::ModelQueryProxy.new(klass: self).including(args)
        end

        def all(args = {})
          Praxis::Mapper::ModelQueryProxy.new(klass: self).all(args)
        end

        def get(args)
          Praxis::Mapper::ModelQueryProxy.new(klass: self).get(args)
        end

        def get!(args)
          Praxis::Mapper::ModelQueryProxy.new(klass: self).get!(args)
        end

        def first
          Praxis::Mapper::ModelQueryProxy.new(klass: self).first
        end

        def last
          Praxis::Mapper::ModelQueryProxy.new(klass: self).last
        end
      end
    end
  end
end