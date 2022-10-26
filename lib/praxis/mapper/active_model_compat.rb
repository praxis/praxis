# frozen_string_literal: true

require 'active_support/concern'

require 'praxis/extensions/field_selection/active_record_query_selector'
require 'praxis/extensions/attribute_filtering/active_record_filter_query_builder'

module Praxis
  module Mapper
    module ActiveModelCompat
      extend ActiveSupport::Concern

      included do
        attr_accessor :_resource
      end

      module ClassMethods
        def _filter_query_builder_class
          Praxis::Extensions::AttributeFiltering::ActiveRecordFilterQueryBuilder
        end

        def _field_selector_query_builder_class
          Praxis::Extensions::FieldSelection::ActiveRecordQuerySelector
        end

        def _pagination_query_builder_class
          Praxis::Extensions::Pagination::ActiveRecordPaginationHandler
        end

        def _praxis_associations
          # Memoize the hash in the model, to avoid recomputing expensive AR reflection lookups
          # NOTE: should this be finalized with the resources? or do we know if all associations and such that are needed here will never change?
          return @_praxis_associations if @_praxis_associations

          orig = reflections.clone

          @_praxis_associations = orig.each_with_object({}) do |(k, v), hash|
            # Assume an 'id' primary key if the system is initializing without AR connected
            # (or without the tables created). This probably means that it's a rake task initializing or so...
            pkey = \
              if v.klass.connected? && v.klass.table_exists?
                v.klass.primary_key
              else
                'id'
              end
            info = { model: v.klass, primary_key: pkey }
            info[:type] = \
              case v
              when ActiveRecord::Reflection::BelongsToReflection
                :many_to_one
              when ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasOneReflection
                :one_to_many
              when ActiveRecord::Reflection::ThroughReflection
                :many_to_many
              else
                raise "Unknown association type: #{v.class.name} on #{v.klass.name} for #{v.name}"
              end
            # Call out any local (i.e., of this model) columns that participate in the association
            info[:local_key_columns] = local_columns_used_for_the_association(info[:type], v)
            info[:remote_key_columns] = remote_columns_used_for_the_association(info[:type], v)

            if v.is_a?(ActiveRecord::Reflection::ThroughReflection)
              info[:through] = v.through_reflection.name # TODO: is this correct?
            end
            hash[k.to_sym] = info
          end
        end

        def _join_foreign_key_for(assoc_reflection)
          maj, min, = ActiveRecord.gem_version.segments
          if maj >= 6 && min >= 1
            assoc_reflection.join_foreign_key.to_sym
          else
            assoc_reflection.join_keys.foreign_key.to_sym
          end
        end

        def _join_primary_key_for(assoc_reflection)
          maj, min, = ActiveRecord.gem_version.segments
          if maj >= 6 && min >= 1
            assoc_reflection.join_primary_key.to_sym
          else
            assoc_reflection.join_keys.key.to_sym
          end
        end

        # Compatible reader accessors
        def _get(condition)
          find_by(condition)
        end

        def _all(conditions = {})
          where(conditions)
        end

        def _add_includes(base, includes)
          base.includes(includes) # includes(nil) seems to have no effect
        end

        def _first
          first
        end

        def _last
          last
        end

        private

        def local_columns_used_for_the_association(type, assoc_reflection)
          case type
          when :one_to_many
            # The associated table  will point to us by key (usually the PK, but not always)
            [_join_foreign_key_for(assoc_reflection)]
          when :many_to_one
            # We have the FKs to the associated model
            [_join_foreign_key_for(assoc_reflection)]
          when :many_to_many
            ref = resolve_closest_through_reflection(assoc_reflection)
            # The associated middle table will point to us by key (usually the PK, but not always)
            [_join_foreign_key_for(ref)] # The foreign key that the last through table points to
          else
            raise "association type #{type} not supported"
          end
        end

        def remote_columns_used_for_the_association(type, assoc_reflection)
          # It seems that since the reflection is the target of the association, using the join_keys.key
          # will always get us the right column
          case type
          when :one_to_many, :many_to_one, :many_to_many
            [_join_primary_key_for(assoc_reflection)]
          else
            raise "association type #{type} not supported"
          end
        end

        # Keep following the association reflections as long as there are middle ones (i.e., through)
        # until we come to the one next to the source
        def resolve_closest_through_reflection(ref)
          return ref unless ref.through_reflection?

          resolve_closest_through_reflection(ref.through_reflection)
        end
      end
    end
  end
end
