# frozen_string_literal: true

require 'sequel'

require 'praxis/mapper/sequel_compat'

# Creates a new in-memory DB, and the necessary tables (and mini-seeds) for the sequel models in this file
def create_and_seed_tables
  sequeldb = Sequel.sqlite
  # sequeldb.loggers = [Logger.new($stdout)] # Uncomment to see sequel logs

  sequeldb.create_table! :sequel_simple_models do
    primary_key :id
    String :simple_name
    Integer :parent_id
    String :parent_uuid
    Integer :other_model_id
    String :added_column
  end
  sequeldb.create_table! :sequel_other_models do
    primary_key :id
  end
  sequeldb.create_table! :sequel_parent_models do
    primary_key :id
    String :uuid
  end
  sequeldb.create_table! :sequel_tag_models do
    primary_key :id
    String :tag_name
  end
  sequeldb.create_table! :sequel_simple_models_sequel_tag_models do
    Integer :sequel_simple_model_id
    Integer :tag_id
  end

  sequeldb[:sequel_parent_models] << { id: 1, uuid: 'deadbeef1' }
  sequeldb[:sequel_parent_models] << { id: 2, uuid: 'deadbeef2' }

  sequeldb[:sequel_other_models] << { id: 11 }
  sequeldb[:sequel_other_models] << { id: 22 }

  sequeldb[:sequel_tag_models] << { id: 1, tag_name: 'blue' }
  sequeldb[:sequel_tag_models] << { id: 2, tag_name: 'red' }

  # Simple model 1 is tagged as blue and red
  sequeldb[:sequel_simple_models_sequel_tag_models] << { sequel_simple_model_id: 1, tag_id: 1 }
  sequeldb[:sequel_simple_models_sequel_tag_models] << { sequel_simple_model_id: 1, tag_id: 2 }
  # Simple model 2 is tagged as red
  sequeldb[:sequel_simple_models_sequel_tag_models] << { sequel_simple_model_id: 2, tag_id: 2 }

  # It's weird to have a parent id and parent uuid (which points to different actual parents)
  # But it allows us to check pointing to both PKs and not PK columns
  sequeldb[:sequel_simple_models] << { id: 1, simple_name: 'Simple1', parent_id: 1, other_model_id: 11, parent_uuid: 'deadbeef1' }
  sequeldb[:sequel_simple_models] << { id: 2, simple_name: 'Simple2', parent_id: 2, other_model_id: 22, parent_uuid: 'deadbeef1' }
end

create_and_seed_tables

class SequelSimpleModel < Sequel::Model
  include Praxis::Mapper::SequelCompat

  many_to_one :parent, class: 'SequelParentModel'
  many_to_one :other_model, class: 'SequelOtherModel'
  many_to_many :tags, class: 'SequelTagModel'
end

class SequelOtherModel < Sequel::Model
  include Praxis::Mapper::SequelCompat
end

class SequelParentModel < Sequel::Model
  include Praxis::Mapper::SequelCompat
  one_to_many :children, class: 'SequelSimpleModel', primary_key: :uuid, key: :parent_uuid
end

class SequelTagModel < Sequel::Model
  include Praxis::Mapper::SequelCompat
end

# A set of resource classes for use in specs
class SequelBaseResource < Praxis::Mapper::Resource
end

class SequelOtherResource < SequelBaseResource
  model SequelOtherModel

  property :display_name, dependencies: [:name]
end

class SequelParentResource < SequelBaseResource
  model SequelParentModel
end

class SequelTagResource < SequelBaseResource
  model SequelTagModel
end

class SequelSimpleResource < SequelBaseResource
  model SequelSimpleModel

  # Forces to add an extra column (added_column)...and yet another (parent_id) that will serve
  # to check that if that's already automatically added due to an association, it won't interfere or duplicate
  property :parent, dependencies: %i[parent added_column parent_id]

  property :name, dependencies: [:simple_name]
end
