require 'singleton'
require 'praxis/extensions/attribute_filtering/filtering_params'

module Praxis
  module Plugins
    module MapperPlugin
      include Praxis::PluginConcern

      class Plugin < Praxis::Plugin
        include Singleton
      end

      module Controller
        extend ActiveSupport::Concern

        included do
          include Praxis::Extensions::FieldExpansion
        end

        def set_selectors
          return unless self.media_type.respond_to?(:domain_model) &&
            self.media_type.domain_model < Praxis::Mapper::Resource

          resolved = Praxis::MediaType::FieldResolver.resolve(self.media_type, self.expanded_fields)
          selector_generator.add(self.media_type.domain_model, resolved)
        end

        def build_query(base_query) # rubocop:disable Metrics/AbcSize
          domain_model = self.media_type&.domain_model
          raise "No domain model defined for #{self.name}. Cannot use the attribute filtering helpers without it" unless domain_model
          
          filters = request.params.filters if request.params&.respond_to?(:filters)
          base_query = domain_model.craft_filter_query( base_query , filters: filters )

          resolved = Praxis::MediaType::FieldResolver.resolve(self.media_type, self.expanded_fields)
          base_query = domain_model.craft_field_selection_query(base_query, selectors: selector_generator.selectors, resolved: resolved)

          # TODO: handle pagination and ordering
          base_query
        end

        def selector_generator
          @selector_generator ||= Praxis::Mapper::SelectorGenerator.new
        end

      end

    end
  end
end
