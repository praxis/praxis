# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/all'

module Praxis
  module Controller
    extend ::ActiveSupport::Concern

    # A Controller always requires the callbacks
    include Praxis::Callbacks

    included do
      attr_reader :request
      attr_accessor :response
    end

    module ClassMethods
      def implements(definition)
        define_singleton_method(:definition) do
          definition
        end

        definition.controller = self
        Application.instance.controllers << self
      end

      def id
        name.gsub('::', '-')
      end
    end

    def initialize(request, response = Responses::Ok.new)
      @request = request
      @response = response
    end

    def inspect
      "#<#{self.class}##{object_id} @request=#{@request.inspect}>"
    end

    def definition
      self.class.definition
    end

    def media_type
      if (response_definition = request.action.responses[response.name])
        response_definition.media_type
      else
        definition.media_type
      end
    end
  end
end
