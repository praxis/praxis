# frozen_string_literal: true
module Praxis
  module Callbacks
    extend ::ActiveSupport::Concern

    included do
      class_attribute :before_callbacks, :after_callbacks, :around_callbacks
      self.before_callbacks = ({})
      self.after_callbacks = ({})
      self.around_callbacks = ({})
    end

    module ClassMethods
      def before(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        before_callbacks[stage_path] ||= []
        before_callbacks[stage_path] << [conditions, block]
      end

      def after(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        after_callbacks[stage_path] ||= []
        after_callbacks[stage_path] << [conditions, block]
      end

      def around(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        around_callbacks[stage_path] ||= []
        around_callbacks[stage_path] << [conditions, block]
      end
    end
  end
end
