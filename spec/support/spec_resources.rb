# frozen_string_literal: true

require 'ostruct'

require 'praxis/mapper/active_model_compat'
class SimpleModel < OpenStruct
  include Praxis::Mapper::ActiveModelCompat
  def self._praxis_associations
    {
      parent: {
        model: ParentModel,
        primary_key: :id,
        type: :many_to_one,
        local_key_columns: [:parent_id],
        remote_key_columns: [:id]
      },
      other_model: {
        model: OtherModel,
        primary_key: :id,
        type: :many_to_one,
        local_key_columns: [:other_model_id],
        remote_key_columns: [:id]
      }
    }
  end
end

class OtherModel < OpenStruct
  include Praxis::Mapper::ActiveModelCompat
  def self._praxis_associations
    {
      parent: {
        model: ParentModel,
        primary_key: :id,
        type: :many_to_one,
        local_key_columns: [:parent_id],
        remote_key_columns: [:id]
      },
      simple_models: {
        model: SimpleModel,
        primary_key: :id,
        type: :many_to_many,
        local_key_columns: [:id],
        remote_key_columns: [:id] # The through table is in the middle where the FKs are...
      }
    }
  end
end

class ParentModel < OpenStruct
  include Praxis::Mapper::ActiveModelCompat
  def self._praxis_associations
    {
      simple_children: {
        model: SimpleModel,
        primary_key: :id,
        type: :one_to_many,
        local_key_columns: [:id],
        remote_key_columns: [:parent_id]
      }
    }
  end
end

class YamlArrayModel < OpenStruct
  include Praxis::Mapper::ActiveModelCompat
  def self._praxis_associations
    {
      parents: {
        model: ParentModel,
        primary_key: :id,
        type: :one_to_many,
        local_key_columns: [:id],
        remote_key_columns: [:parent_id]
      }
    }
  end
end

# A set of resource classes for use in specs
class BaseResource < Praxis::Mapper::Resource
  def href
    base_href = '' # "/api"
    base_href + "/#{self.class.collection_name}/#{id}"
  end

  property :href, dependencies: [:id]
end

class OtherResource < BaseResource
  model OtherModel

  property :display_name, dependencies: [:name]
end

class ParentResource < BaseResource
  model ParentModel

  property :display_name, dependencies: %i[simple_name id other_attribute]
end

class SimpleResource < BaseResource
  model SimpleModel

  resource_delegate other_model: [:other_attribute]

  def other_resource
    other_model
  end

  property :aliased_method, dependencies: %i[column1 other_model]
  property :other_resource, dependencies: [:other_model]

  property :parent, dependencies: %i[parent added_column]

  property :name, dependencies: [:simple_name]
  property :direct_other_name, dependencies: ['other_model.name']
  property :aliased_other_name, dependencies: ['other_model.display_name']

  property :everything, dependencies: [:*]
  property :everything_from_parent, dependencies: ['parent.*']
  property :circular_dep, dependencies: %i[circular_dep column1]
  property :no_deps, dependencies: []

  property :deep_nested_deps, dependencies: ['parent.simple_children.other_model.parent.display_name']
end

class YamlArrayResource < BaseResource
  model YamlArrayModel
end
