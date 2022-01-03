# frozen_string_literal: true

module Praxis
  module BootloaderStages
    class PluginSetup < Stage
      def execute
        application.plugins.each do |_config_key, plugin|
          plugin.setup!
        end
      end
    end
  end
end
