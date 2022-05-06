# frozen_string_literal: true

module Praxis
  module Mapper
    module Resources
      module Callbacks
        extend ::ActiveSupport::Concern

        included do
          class_attribute :before_callbacks, :after_callbacks, :around_callbacks
          self.before_callbacks = Hash.new { |h, method| h[method] = [] }
          self.after_callbacks = Hash.new { |h, method| h[method] = [] }
          self.around_callbacks = Hash.new { |h, method| h[method] = [] }
        end

        module ClassMethods
          def before(method, function = nil, &block)
            target = function ? function.to_sym : block
            before_callbacks[method] << target
          end

          def after(method, function = nil, &block)
            target = function ? function.to_sym : block
            after_callbacks[method] << target
          end

          def around(method, function = nil, &block)
            target = function ? function.to_sym : block
            around_callbacks[method] << target
          end
        end
      end
    end
  end
end