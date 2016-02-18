module Praxis

  module PluginConcern
    extend ::ActiveSupport::Concern

    included do
      @setup = false
    end

    module ClassMethods
      PLUGIN_CLASSES = [
        :Request,
        :Controller,
        :ResourceDefinition,
        :ActionDefinition,
        :Response,
        :ApiGeneralInfo
      ]

      def setup!
        return if @setup

        PLUGIN_CLASSES.each do |name|
          if self.constants.include?(name)
            inject!(name)
          end
        end

        @setup = true
      end

      def inject!(name)
        plugin = self.const_get(name)
        praxis = Praxis.const_get(name)

        praxis.include(plugin)
      end

    end
  end

end
