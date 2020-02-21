require 'active_support/concern'

module Praxis::Mapper
  module SequelCompat
    extend ActiveSupport::Concern

``    included do
      attr_accessor :_resource
    end

    module ClassMethods
      def _filter_query_builder_class
        Praxis::Extensions::SequelFilterQueryBuilder
      end

      def _praxis_associations
        orig = self.association_reflections.clone

        orig.each do |k,v|
          v[:model] = v.associated_class
          if v.respond_to?(:primary_key)
            v[:primary_key] = v.primary_key
          else
            # FIXME: figure out exactly what to do here. 
            # not super critical, as we can't track these associations
            # directly, but it would be nice to traverse these
            # properly.
            v[:primary_key] = :unsupported
          end
        end
        orig
      end

    end

  end
end
