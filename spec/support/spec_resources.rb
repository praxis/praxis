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
  property :aliased_simple_children, as: :simple_children

  def display_name
    "#{id}-#{name}"
  end
  batch_computed(:computed_display, with_instance_method: false) do |rows_by_id:|
    rows_by_id.transform_values do |v|
      "BATCH_COMPUTED_#{v.display_name}"
    end
  end
end

class SimpleResource < BaseResource
  include Praxis::Mapper::Resources::Callbacks

  model SimpleModel

  resource_delegate other_model: [:other_attribute]

  def other_resource
    other_model
  end

  def overriden_aliased_association
    # My custom override (instead of the auto-generated delegator)
    # For fun, we'll just return the raw model, without wrapping it in the resource
    record.other_model
  end

  batch_computed(:computed_name) do |rows_by_id:|
    rows_by_id.transform_values do |v|
      "BATCH_COMPUTED_#{v.name}"
    end
  end

  property :multi_column, dependencies: %i[column1 simple_name]
  property :aliased_method, dependencies: %i[column1 other_model]
  property :other_resource, dependencies: [:other_model]
  property :parent, dependencies: %i[parent added_column]

  property :name, dependencies: [:nested_name]
  property :nested_name, dependencies: [:simple_name]

  property :direct_other_name, dependencies: ['other_model.name']
  property :aliased_other_name, dependencies: ['other_model.display_name']

  property :everything, dependencies: [:*]
  property :everything_from_parent, dependencies: ['parent.*']
  property :circular_dep, dependencies: %i[circular_dep column1]
  property :no_deps, dependencies: []
  property :deep_nested_deps, dependencies: ['parent.simple_children.other_model.parent.display_name']
  
  property :aliased_association, as: :other_model
  property :deep_aliased_association, as: 'parent.simple_children'
  property :overriden_aliased_association, as: :other_model
  property :aliased_parent, as: :parent
  property :deep_overriden_aliased_association, as: 'parent.simple_children' # TODO!!! if I change it to 'aliased_parent.aliased_simple_children' things come empty!!!
  property :sub_struct, as: :self

  property :true_struct, dependencies: [:name, :sub_id]
  # property :true_struct, dependencies: [:sub_id]
  property :sub_id, dependencies: [:inner_sub_id]
  property :inner_sub_id, dependencies: [:id]

  property :agroup, dependencies: [:agroup_id, :agroup_name]
  property :agroup_id, dependencies: [:id]
  property :agroup_name, dependencies: [:name]

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

  around(:argsonly, :do_around_argsonly)
  def do_around_argsonly(name)
    record.around_count += 50
    record.name += name.to_s
    yield(name)
  end

  def argsonly(name)
    record.name += "-#{name}"
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
  def update!(**payload)
    payload
  end

  signature(:singlearg_update!) do
    attribute :string_param, String, null: false
    attribute :struct_param do
      attribute :id, Integer
    end
  end
  def singlearg_update!(payload)
    payload
  end

  # Instance method: create, to make sure we support both an instance and a class method signature
  signature(:create) do
    attribute :id, String
  end
  def create(id:)
    id
  end

  signature('self.create') do
    attribute :name, String, regexp: /Praxis/
    attribute :payload, TypedResource.signature(:update!), required: true
  end

  def self.create(**payload)
    payload
  end

  signature('self.singlearg_create') do
    attribute :name, String, regexp: /Praxis/
    attribute :payload, TypedResource.signature(:update!), required: true
  end

  def self.singlearg_create(payload)
    payload
  end
end
