require 'active_support/concern'
module Praxis

  module Controller
    extend ActiveSupport::Concern

    included do
      attr_reader :request
      attr_accessor :response
    end

    module ClassMethods
      def action(name)
        config.actions.fetch(name)
      end

      def config
        (self.name + "Config").constantize
      end
    end

    def initialize(request)
      @request = request
      @response = DefaultResponse.new
    end

  end
end
