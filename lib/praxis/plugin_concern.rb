# frozen_string_literal: true

module Praxis
  module PluginConcern
    extend ::ActiveSupport::Concern

    included do
      @setup = false
    end

    module ClassMethods
      PLUGIN_CLASSES = %i[
        Request
        Controller
        EndpointDefinition
        ActionDefinition
        Response
        ApiGeneralInfo
      ]

      def setup!
        return if @setup

        PLUGIN_CLASSES.each do |name|
          inject!(name) if constants.include?(name)
        end

        @setup = true
      end

      def inject!(name)
        plugin = const_get(name)
        praxis = Praxis.const_get(name)

        praxis.include(plugin)
      end
    end
  end
end
