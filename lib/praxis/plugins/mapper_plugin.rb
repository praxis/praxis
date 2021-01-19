require 'singleton'

require 'praxis/extensions/field_selection'

module Praxis  
  module Plugins
    module MapperPlugin
      include Praxis::PluginConcern

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

          before :action do |controller, _callee|
            # Set the selectors, unless they're set already
            controller.set_selectors unless controller.selector_generator.selectors
          end
        end

        def set_selectors
          return unless self.media_type.respond_to?(:domain_model) &&
            self.media_type.domain_model < Praxis::Mapper::Resource

          selector_generator.add(self.media_type.domain_model, self.expanded_fields)
        end

        def build_query(base_query, type: :active_record) # rubocop:disable Metrics/AbcSize
          domain_model = self.media_type&.domain_model
          raise "No domain model defined for #{self.name}. Cannot use the attribute filtering helpers without it" unless domain_model
          
          filters = request.params.filters if request.params&.respond_to?(:filters)
          # Handle filters
          base_query = domain_model.craft_filter_query( base_query , filters: filters )
          # Handle field and nested field selection
          base_query = domain_model.craft_field_selection_query(base_query, selectors: selector_generator.selectors)
          # handle pagination and ordering
          base_query = _craft_pagination_query(query: base_query, type: type) if self.respond_to?(:_pagination)

          base_query
        end

        def selector_generator
          @selector_generator ||= Praxis::Mapper::SelectorGenerator.new
        end

      end

    end
  end
end
