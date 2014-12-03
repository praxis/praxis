module Praxis
  module BootloaderStages
    class PluginSetup < Stage

      def execute
        application.plugins.each do |config_key, plugin|
          plugin.setup!
        end
      end

    end
  end
end
