require 'active_support/inflector'

module Praxis

  module Controller
    
    def self.included(klass)

      klass.send(:include, InstanceMethods)
      klass.extend ClassMethods
      Application.instance.controllers << klass
      klass.instance_eval do
        attr_reader :request
        attr_accessor :response
        @before_callbacks = Hash.new
        @after_callbacks = Hash.new
        @around_callbacks = Hash.new
      end

    end

    module ClassMethods
      attr_reader :before_callbacks, :after_callbacks, :around_callbacks

      def implements(definition)
        define_singleton_method(:definition) do
          definition
        end
        definition.controller = self
      end

      def actions
        (self.respond_to? :definition) ? definition.actions : {} 
      end

      def action(name)
        actions.fetch(name)
      end

      def before(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        @before_callbacks[stage_path] ||= Array.new
        @before_callbacks[stage_path] << [conditions, block]
      end

      def after(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        @after_callbacks[stage_path] ||= Array.new
        @after_callbacks[stage_path] << [conditions, block]
      end
      
      def around(*stage_path, **conditions, &block)
        stage_path = [:action] if stage_path.empty?
        @around_callbacks[stage_path] ||= Array.new
        @around_callbacks[stage_path] << [conditions, block]
      end
      
    end


    module InstanceMethods 
      def initialize(request, response=Responses::Ok.new)
        @request = request
        @response = response
      end
    end
  end
end
