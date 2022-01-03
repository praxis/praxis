# frozen_string_literal: true

module Praxis
  module BootloaderStages
    class PluginConfigPrepare < Stage
      def execute
        application.plugins.each do |config_key, plugin|
          attribute = Attributor::Attribute.new(Attributor::Struct) {}

          plugin.config_attribute = attribute
          plugin.prepare_config!(attribute.type)

          application.config.class.attributes[config_key] = plugin.config_attribute
        end
      end
    end
  end
end
