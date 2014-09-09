require 'active_support/inflector'
require 'active_support/concern'
require 'active_support/all'

module Praxis
  module Controller
    extend ::ActiveSupport::Concern

    included do
      class_attribute :before_callbacks, :after_callbacks, :around_callbacks

      self.before_callbacks = Hash.new
      self.after_callbacks = Hash.new
      self.around_callbacks = Hash.new
    end

    module ClassMethods
      def implements(definition)
        define_singleton_method(:definition) do
          definition
        end

        definition.controller = self
        Application.instance.controllers << self
      end

      def actions
        (self.respond_to? :definition) ? definition.actions : {}
      end

      def action(name)
        actions.fetch(name)
      end

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

    def initialize(request, response=Responses::Ok.new)
      @request = request
      @response = response
    end

    def request
      @request
    end

    def response
      @response
    end

    def response=(value)
      @response = value
    end
  end
end
