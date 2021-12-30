# frozen_string_literal: true
module Praxis
  module BootloaderStages
    class PluginConfigLoad < Stage
      def execute
        application.plugins.each do |config_key, plugin|
          context = [plugin.class.name]
          value = plugin.load_config!
          object = plugin.config_attribute.load(value, context)

          application.config.send("#{config_key}=", object) if object

          plugin.config = application.config.send(config_key.to_s)
        end
      end
    end
  end
end
