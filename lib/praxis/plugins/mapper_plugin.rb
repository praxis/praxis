# frozen_string_literal: true
require 'singleton'

require 'praxis/extensions/field_selection'

module Praxis
  module Plugins
    module MapperPlugin
      include Praxis::PluginConcern

      # The Mapper plugin is an overarching set of things to include in your application
      # when you want to use the rendring, field_selection, filtering (and potentially pagination) extensions
      # To use the plugin, set it up like any other plugin by registering to the bootloader.
      # Typically you'd do that in environment.rb, inside the `Praxis::Application.configure do |application|` block, by:
      #   application.bootloader.use Praxis::Plugins::MapperPlugin
      #
      # The plugin accepts only 1 configuration option thus far, which you can set inside the same block as:
      #   application.config.mapper.debug_queries = true
      # when debug_queries is set to true, the system will output information about the expanded fields
      # and associations that the system ihas calculated necessary to pull from the DB, based on the requested
      # API fields, API filters and `property` dependencies defined in the domain models (i.e., resources)
      class Plugin < Praxis::Plugin
        include Singleton

        def config_key
          :mapper
        end

        def load_config!
          {} # override the default one, since we don't necessarily want to configure it via a yaml file.
        end

        def prepare_config!(node)
          node.attributes do
            attribute :debug_queries, Attributor::Boolean, default: false,
                                                           description: 'Weather or not to log debug information about queries executed in the build_query automation module'
          end
        end
      end

      module Controller
        extend ActiveSupport::Concern

        included do
          include Praxis::Extensions::Rendering
          include Praxis::Extensions::FieldExpansion
        end

        def build_query(base_query)
          domain_model = media_type&.domain_model
          raise "No domain model defined for #{name}. Cannot use the attribute filtering helpers without it" unless domain_model

          filters = request.params.filters if request.params&.respond_to?(:filters)
          # Handle filters
          base_query = domain_model.craft_filter_query(base_query, filters: filters)
          # Handle field and nested field selection
          base_query = domain_model.craft_field_selection_query(base_query, selectors: selector_generator.selectors)
          # handle pagination and ordering if the pagination extention is included
          base_query = domain_model.craft_pagination_query(base_query, pagination: _pagination) if respond_to?(:_pagination)

          base_query
        end

        def selector_generator
          return unless media_type.respond_to?(:domain_model) &&
                        media_type.domain_model < Praxis::Mapper::Resource

          @selector_generator ||= \
            Praxis::Mapper::SelectorGenerator.new.add(media_type.domain_model, expanded_fields)
        end
      end
    end
  end
end
