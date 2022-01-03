# frozen_string_literal: true

module Praxis
  module BootloaderStages
    class PluginLoader < Stage
      def initialize(name, context, **opts)
        super

        stages << PluginConfigPrepare.new(:prepare, context, parent: self)
        stages << PluginConfigLoad.new(:load, context, parent: self)
        stages << PluginSetup.new(:setup, context, parent: self)
      end
    end
  end
end
