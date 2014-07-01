require 'active_support/concern'
require 'active_support/inflector'

module Praxis

  module Controller
    extend ActiveSupport::Concern

    included do
      attr_reader :request
      attr_accessor :response
      Application.instance.controllers << self
      self.instance_eval do
        @before_callbacks = Hash.new
        @after_callbacks = Hash.new
      end

    end

    module ClassMethods
      attr_reader :before_callbacks, :after_callbacks

      def implements(definition)
        define_singleton_method(:definition) do
          definition
        end
        definition.controller = self
      end

      def actions
        definition.actions
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

    end


    def initialize(request, response=Responses::Default.new)
      @request = request
      @response = response
    end

  end
end
