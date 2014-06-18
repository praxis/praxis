require 'active_support/concern'
module Praxis

  module Controller
    extend ActiveSupport::Concern

    included do
      attr_reader :request
      attr_accessor :response
      Application.instance.controllers << self
    end

    module ClassMethods
      def action(name)
        api_resource.actions.fetch(name)
      end

      def api_resource
        ("ApiResources::" + self.name).constantize
      end
    end

    def initialize(request)
      @request = request
      @response = DefaultResponse.new
    end

  end
end
