require 'active_support/concern'
require 'active_support/inflector'

module Praxis

  module Controller
    extend ActiveSupport::Concern

    included do
      attr_reader :request
      attr_accessor :response
      Application.instance.controllers << self
    end

    module ClassMethods

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

    end

    def initialize(request, response=Responses::Default.new)
      @request = request
      @response = response
    end

  end
end
