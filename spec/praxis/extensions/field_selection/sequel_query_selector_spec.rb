# frozen_string_literal: true

require 'spec_helper'
require 'sequel'

require 'praxis/extensions/field_selection/sequel_query_selector'

class QTest
  attr_reader :object, :cols

  def initialize
    @object = {}
    @cols = []
  end

  def eager(hash)
    raise 'we are only calling eager one at a time!' if hash.keys.size > 1

    name = hash.keys.first
    # Actually call the incoming proc with an instance of QTest, to collect the further select/eager calls
    @object[name] = hash[name].call(QTest.new)
    self
  end

  def select(*names)
    @cols += names.map(&:column)
    self
  end

  def dump
    eagers = @object.transform_values(&:dump)
    {
      columns: @cols,
      eagers: eagers
    }
  end
end

describe Praxis::Extensions::FieldSelection::SequelQuerySelector do
  # Pay the price for creating and connecting only in this spec instead in spec helper
  # this way all other specs do not need to be slower and it's a better TDD experience

  let(:selector_fields) do
    {
      name: true,
      other_model: {
        id: true
      },
      parent: {
        children: true
      },
      tags: {
        tag_name: true
      }
    }
  end
  let(:expected_select_from_to_query) do
    # The columns to select from the top Simple model
    [
      :simple_name, # from the :name alias
      :added_column, # from the extra column defined in the parent property
      :id, # We always load the primary keys
      :other_model_id, # the FK needed for the other_model association
      :parent_id # the FK needed for the parent association
    ]
  end

  let(:selector_node) { Praxis::Mapper::SelectorGenerator.new.add(SequelSimpleResource, selector_fields).selectors }
  subject { described_class.new(query: query, selectors: selector_node, debug: debug) }

  context 'generate' do
    let(:debug) { false }
    context 'using the real models and DB' do
      let(:query) { SequelSimpleModel }

      it 'calls the select columns for the top level, and includes the right association hashes' do
        ds = subject.generate
        opts = ds.opts
        # Top model is our simplemodel
        expect(opts[:model]).to be(SequelSimpleModel)
        selected_column_names = opts[:select].map(&:column)
        expect(selected_column_names).to match_array(expected_select_from_to_query)
        # 2 Eager loaded associations as well
        expect(opts[:eager].keys).to match_array(%i[other_model parent tags])
        # We can not introspect those eagers, as they are procs...but at least validate they are
        expect(opts[:eager][:other_model]).to be_a Proc
        expect(opts[:eager][:parent]).to be_a Proc

        # Also, let's make sure the query actually works by making Sequel attempt to retrieve it and finding the right things.
        result = ds.all
        # 2 simple models
        expect(result.size).to be 2
        # First simple model points to other_model 11 and parent 1
        simple_one = result.find { |i| i.id == 1 }
        expect(simple_one.other_model.id).to be 11
        expect(simple_one.parent.id).to be 1
        # also, its' parent in turn has 2 children (1 and 2) linked by its parent_uuid
        expect(simple_one.parent.children.map(&:id)).to match_array([1, 2])
        # Has the blue and red tags
        expect(simple_one.tags.map(&:tag_name)).to match_array(%w[blue red])

        # second simple model points to other_model 22 and parent 2
        simple_two = result.find { |i| i.id == 2 }
        expect(simple_two.other_model.id).to be 22
        expect(simple_two.parent.id).to be 2
        # also, its' parent in turn has no children (as no simple models point to it by uuid)
        expect(simple_two.parent.children.map(&:id)).to be_empty
        # Also has the red tag
        expect(simple_two.tags.map(&:tag_name)).to match_array(['red'])
      end
      it 'calls the explain debug method if enabled' do
        suppress_output do
          # Actually make it run all the way...but suppressing the output
          subject.generate
        end
      end
    end
    context 'just mocking the query' do
      let(:query) { QTest.new }

      it 'creates the right recursive lambdas for the eager loading' do
        ds = subject.generate
        result = ds.dump
        expect(result[:columns]).to match_array(expected_select_from_to_query)
        # 2 eager loads
        expect(result[:eagers].keys).to match_array(%i[other_model parent tags])
        # 1 - other model
        other_model_eagers = result[:eagers][:other_model]
        expect(other_model_eagers[:columns]).to match_array([:id])

        # 2 - parent association
        parent_eagers = result[:eagers][:parent]
        expect(parent_eagers[:columns]).to match_array(%i[id uuid]) # uuid is necessary for the "children" assoc
        expect(parent_eagers[:eagers].keys).to match_array([:children])
        # 2.1 - children association off of the parent
        parent_children_eagers = parent_eagers[:eagers][:children]
        expect(parent_children_eagers[:columns]).to match_array(%i[id parent_uuid]) # parent_uuid is required for the assoc
        expect(parent_children_eagers[:eagers]).to be_empty

        # 3 - tags association
        tags_eagers = result[:eagers][:tags]
        expect(tags_eagers[:columns]).to match_array(%i[id tag_name]) # uuid is necessary for the "children" assoc
        expect(tags_eagers[:eagers].keys).to be_empty
      end
    end
  end
end
