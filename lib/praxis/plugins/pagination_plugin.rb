# frozen_string_literal: true
require 'singleton'
require 'praxis/extensions/pagination'

# The PaginationPlugin can be configured to take advantage of adding pagination and sorting to
# your DB queries.
# When combined with the MapperPlugin, there is no extra configuration that needs to be done for
# the system to appropriately identify the pagination and order parameters in the API, and translate
# that in to the appropriate queries to fetch.
#
# To use this plugin without the MapperPlugin (probably a rare case), one can apply the appropriate
# clauses onto a query, by directly calling (in the controller) the `craft_pagination_query` method
# of the domain_model associated to the controller's mediatype.
# For example, here's how you can manually use this extension in a fictitious users index action:
# def index
#   base_query = User.all # Start by not excluding any user
#   domain_model = self.media_type.domain_model
#   objs = domain_model.craft_pagination_query(base_query, pagination: _pagination)
#   display(objs)
# end
#
# This plugin accepts configuration about the default behavior of pagination.
# Any of these configs can individually be overidden when defining each Pagination/Order parameters
# in any of the Endpoint actions.
#
# Example configuration for this plugin
# Praxis::Application.configure do |application|
#   application.bootloader.use Praxis::Plugins::PaginationPlugin, {
#     # The maximum number of results that a paginated response will ever allow
#     max_items: 500,  # Unlimited by default,
#     # The default page size to use when no `items` is specified
#     default_page_size: 100,
#     # Disallows the use of the page type pagination mode when true (i.e., using 'page=' parameter)
#     disallow_paging_by_default: true, # Default false
#     # Disallows the use of the cursor type pagination mode when true (i.e., using 'by=' or 'from=' parameter)
#     disallow_cursor_by_default: true, # Default false
#     # The default mode params to use
#     paging_default_mode: {by: :uuid}, # Default {by: :uid}
#     # Weather or not to enforce that all requested sort fields are part of the media_type attributes
#     # when false (not enforced) only the first field would be checked
#     sorting: {
#       enforce_all_fields: false       # Default true
#     }
#   end
# end
#
# This would be applied to all controllers etc...so if one does not that
# It can easily add the `include Praxis::Extensions::Pagination` for every controller
# and use the class `Praxis::Types::PaginationParams.xxx yyy` stanzas to configure defaults

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
            attribute :sorting do
              attribute :enforce_all_fields, Attributor::Boolean, default: Praxis::Types::OrderingParams.enforce_all_fields
            end
          end
        end

        def setup!
          config.each do |name, val|
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
