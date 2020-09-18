require 'singleton'
require 'praxis/extensions/pagination'

# Initial Proof Of Concept, for using this instead of the individual `include Praxis::Extensions::Pagination`
# This would allow to provide some config...(which is better than setting class methods)
# ...but it is not clear how to "synchronize that"
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
          {} # override the default one, since we don't necessarily want to configure it via a yaml file.
        end

        def prepare_config!(node)
          # FIXME: We might need a better way to expose the config from here, but in a way
          # that we could set it back to the Pagination classes...
          node.attributes do
            # attribute :???, Attributor::Boolean, default: false,
            #   description: '???'
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
