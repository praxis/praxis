module Praxis
  module Callbacks
    extend ::ActiveSupport::Concern

    included do
      class_attribute :before_callbacks, :after_callbacks, :around_callbacks
      self.before_callbacks = Hash.new
      self.after_callbacks = Hash.new
      self.around_callbacks = Hash.new
    end
    
    module ClassMethods
 
      def before(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        before_callbacks[stage_path] ||= Array.new
        before_callbacks[stage_path] << [conditions, block]
      end
      
      def after(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        after_callbacks[stage_path] ||= Array.new
        after_callbacks[stage_path] << [conditions, block]
      end
      
      def around(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        around_callbacks[stage_path] ||= Array.new
        around_callbacks[stage_path] << [conditions, block]
      end
    end
  end
end