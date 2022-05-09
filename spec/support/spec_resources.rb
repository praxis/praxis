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

class TypedModel < OpenStruct
  def self._praxis_associations
    {}
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
  include Praxis::Mapper::Resources::Callbacks

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

  before(:update!, :do_before_update)
  around(:update!, :do_around_update_nested)
  around(:update!, :do_around_update)
  # Define an after as a proc
  after(:update!) do |number:|
    _unused = number
    record.after_count += 1
  end

  def do_before_update(number:)
    _unused = number
    record.before_count += 1
  end

  def do_around_update_nested(number:)
    record.around_count += 100
    yield(number: number)
  end

  def do_around_update(number:)
    record.around_count += 50
    yield(number: number)
  end

  around(:change_name, :do_around_change_name)
  after(:change_name, :do_after_change_name)
  # Define a before as a proc
  before(:change_name) do |name, force:|
    _unused = force
    record.before_count += 1
    record.name = name
    record.force = false # Force always false in before
  end

  def do_after_change_name(name, force:)
    _unused = force
    record.after_count += 1
    record.name += "-#{name}"
  end

  def do_around_change_name(name, force:)
    record.around_count += 50

    record.name += "-#{name}"
    yield(name, force: force)
  end

  # Appends the name and overrides the force
  def change_name(name, force:)
    record.name += "-#{name}"
    record.force = force
    self
  end

  # Adds 1000 to the around count, plus whatever has been accumulated in before_count
  def update!(number:)
    record.around_count += number + record.before_count
    self
  end
end

class YamlArrayResource < BaseResource
  model YamlArrayModel
end

class TypedResource < BaseResource
  include Praxis::Mapper::Resources::TypedMethods

  model TypedModel

  signature(:update!) do
    attribute :string_param, String, null: false
    attribute :struct_param do
      attribute :id, Integer
    end
  end
  def update!(payload)
    payload
  end

  signature(:create) do
    attribute :name, String, regexp: /Praxis/
    attribute :payload, TypedResource.signature(:update!), required: true
  end

  def self.create(payload)
    payload
  end
end
