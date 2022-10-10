# frozen_string_literal: true

module Praxis
  module Mapper
    module Resources
      module QueryMethods
        extend ::ActiveSupport::Concern

        # Includes some limited, but handy query methods so we can transparently
        # use them from the resource layer, and get wrapped resources from it
        module ClassMethods
          def including(args)
            QueryProxy.new(klass: self).including(args)
          end

          def all(...)
            QueryProxy.new(klass: self).all(...)
          end

          def get(args)
            QueryProxy.new(klass: self).get(args)
          end

          def get!(args)
            QueryProxy.new(klass: self).get!(args)
          end

          def first
            QueryProxy.new(klass: self).first
          end

          def last
            QueryProxy.new(klass: self).last
          end
        end
      end
    end
  end
end
