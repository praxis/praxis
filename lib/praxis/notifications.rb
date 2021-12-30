require 'active_support/notifications'

require 'singleton'

module Praxis
  module Notifications
    include Praxis::PluginConcern

    class Plugin < Praxis::Plugin
      include Singleton

      def config_key
        :notifications # 'praxis.notifications'
      end
    end

    def self.publish(name, *args)
      ActiveSupport::Notifications.publish(name, *args)
    end

    def self.instrument(name, payload = {}, &block)
      ActiveSupport::Notifications.instrument(name, **payload, &block)
    end

    def self.subscribe(*args, &block)
      ActiveSupport::Notifications.subscribe(*args, &block)
    end

    def self.subscribed(callback, *args, &block)
      ActiveSupport::Notifications.subscribed(callback, *args, &block)
    end

    def self.unsubscribe(subscriber_or_name)
      ActiveSupport::Notifications.unsubscribe(subscriber_or_name)
    end
  end
end
