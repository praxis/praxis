require 'active_support/concern'


module Praxis::Mapper
  module SequelCompat
    extend ActiveSupport::Concern

    included do
      attr_accessor :_resource
      alias_method :find_by, :find # Easy way to be method compatible with AR
    end

    module ClassMethods
      def _filter_query_builder_class
        # TODO: refactor the query builder, and add the explicit require in this file
        Praxis::Extensions::SequelFilterQueryBuilder
      end

      def _field_selector_query_builder_class
        Praxis::Extensions::FieldSelection::SequelQuerySelector
      end

      def _pagination_query_builder_class
        Praxis::Extensions::Pagination::SequelPaginationHandler
      end

      def _praxis_associations
        orig = self.association_reflections.clone
        orig.each do |k,v|
          v[:model] = v.associated_class
          v[:local_key_columns] = local_columns_used_for_the_association(v[:type], v)
          v[:remote_key_columns] = remote_columns_used_for_the_association(v[:type], v)
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

      private
      def local_columns_used_for_the_association(type, assoc_reflection)
        case type
        when :one_to_many
          # The associated table (or middle table if many to many) will point to us by PK
          assoc_reflection[:primary_key_columns]
        when :many_to_one
          # We have the FKs to the associated model
          assoc_reflection[:keys]
        when :many_to_many
          # The middle table if many to many) will point to us by key (usually the PK, but not always)
          assoc_reflection[:left_primary_keys]
        else 
          raise "association type #{type} not supported"
        end
      end

      def remote_columns_used_for_the_association(type, assoc_reflection)
        case type
        when :one_to_many
          # The columns in the associated table that will point back to the original association
          assoc_reflection[:keys]
        when :many_to_one
          # The columns in the associated table that the children will point to (usually the PK, but not always) ??
          [assoc_reflection.associated_class.primary_key]
        when :many_to_many
          # The middle table if many to many will point to us by key (usually the PK, but not always) ??
          [assoc_reflection.associated_class.primary_key]
        else 
          raise "association type #{type} not supported"
        end
      end

    end

  end
end