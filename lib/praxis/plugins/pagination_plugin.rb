require 'singleton'
require 'praxis/extensions/pagination'

# Initial Proof Of Concept, for using this instead of the individual `include Praxis::Extensions::Pagination`
# This would allow to provide some config...(which is better than setting class methods)
# ...but it is not clear how to "synchronize that"
# Example configuration for this plugin
# Praxis::Application.configure do |application|
#   application.bootloader.use Praxis::Plugins::PaginationPlugin, {
#     max_items: 500,  # Unlimited by default,
#     default_page_size: 100,
#     disallow_paging_by_default: false,
#     # See all available options below
#   end
# end

module Praxis
  module Plugins
    module PaginationPlugin
      include Praxis::PluginConcern

      class Plugin < Praxis::Plugin
        include Singleton

        def config_key
          :pagination
        end

        def load_config!
          @options || {}
        end

        def prepare_config!(node)
          node.attributes do
            attribute :max_items, Integer # Defaults to unlimited
            attribute :default_page_size, Integer, default: Praxis::Types::PaginationParams.default_page_size
            attribute :paging_default_mode, Hash, default: Praxis::Types::PaginationParams.paging_default_mode
            attribute :disallow_paging_by_default, Attributor::Boolean, default: Praxis::Types::PaginationParams.disallow_paging_by_default
            attribute :disallow_cursor_by_default, Attributor::Boolean, default: Praxis::Types::PaginationParams.disallow_cursor_by_default
            attribute :disallow_cursor_by_default, Attributor::Boolean, default: Praxis::Types::PaginationParams.disallow_cursor_by_default
            attribute :sorting do
              attribute :enforce_all_fields, Attributor::Boolean, default: Praxis::Types::OrderingParams.enforce_all_fields
            end
          end
        end

        def setup!
          self.config.each do |name, val|
            if name == :sorting
              val.each do |ordername, orderval|
                Praxis::Types::OrderingParams.send(ordername, orderval)
              end
            else
              Praxis::Types::PaginationParams.send(name, val)
            end
          end      
        end
      end

      module Controller
        extend ActiveSupport::Concern

        included do
          include Praxis::Extensions::Pagination
        end
      end
    end
  end
end
