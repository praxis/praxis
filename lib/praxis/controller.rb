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
    end

    def initialize(request, response=Responses::Ok.new)
      @request = request
      @response = response
    end

#    def request
#      @request
#    end
#
#    def response
#      @response
#    end
#
#    def response=(value)
#      @response = value
#    end
  end
end
