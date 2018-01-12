require 'praxis/extensions/attribute_filtering/filtering_params'
require 'praxis/extensions/attribute_filtering/query_builder'

# To include in a controller
module Praxis
  module Extensions
    module AttributeFiltering
      extend ActiveSupport::Concern
      
      def build_query(base_query) # rubocop:disable Metrics/AbcSize

        domain_model = self.media_type&.domain_model
        raise "No domain model defined for #{self.name}. Cannot use the attribute filtering helpers without it" unless domain_model
        
        filters = request.params.filters if request.params&.respond_to?(:filters)
        base_query = domain_model.craft_query( base_query , filters )

        # TODO: add the field selector...and the pagination...and the ordering...
        resolved = Praxis::MediaType::FieldResolver.resolve(self.media_type, self.expanded_fields)
        base_query = FieldSelection::ActiveRecordQuerySelector.new(ds: base_query, model: domain_model.model,
                                        selectors: identity_map.selectors, resolved: resolved).generate

        # TODO: handle pagination and ordering
        base_query
      end
    end
  end
end
