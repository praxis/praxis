module Praxis
  module Extensions
    module MapperSelectors
      extend ActiveSupport::Concern
      include FieldExpansion

      def set_selectors
        return unless self.media_type.respond_to?(:domain_model) &&
          self.media_type.domain_model < Praxis::Mapper::Resource

        resolved = Praxis::MediaType::FieldResolver.resolve(self.media_type, self.expanded_fields)
        identity_map.add_selectors(self.media_type.domain_model, resolved)
      end
    end
  end
end
