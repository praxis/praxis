require 'spec_helper'

require_relative '../support/spec_resources_active_model.rb'
require 'praxis/extensions/attribute_filtering'
require 'praxis/extensions/attribute_filtering/active_record_filter_query_builder'

describe Praxis::Extensions::AttributeFiltering::ActiveRecordFilterQueryBuilder do
  let(:root_resource) { ActiveBookResource }
  let(:filters_map) { root_resource.instance_variable_get(:@_filters_map)}
  let(:base_model) { root_resource.model }
  let(:base_query) { base_model }
  let(:instance) { described_class.new(query: base_query, model: base_model, filters_map: filters_map) }

  shared_examples 'subject_equivalent_to' do |expected_result|
    it do
      loaded_ids = subject.all.map(&:id).sort
      expected_ids = expected_result.all.map(&:id).sort
      expect(loaded_ids).to_not be_empty
      expect(loaded_ids).to eq(expected_ids)
    end
  end

  context 'initialize' do
    it 'sets the right things to the instance' do
      instance
      expect(instance.query).to eq(base_query)
      expect(instance.table).to eq(base_model.table_name)
      expect(instance.attr_to_column).to eq(filters_map)
      expect(instance.instance_variable_get(:@last_join_alias)).to eq(base_model.table_name)
      expect(instance.instance_variable_get(:@alias_counter)).to eq(0)      
    end
  end
  context 'build_clause' do
    subject { instance.build_clause(filters) }
    let(:filters) { Praxis::Types::FilteringParams.load(filters_string)}

    context 'with no filters' do
      let(:filters_string) { '' }
      it 'does not modify the query' do
        expect(subject).to be(base_query)
      end
    end
    context 'by a simple field' do
      context 'that maps to the same name' do
        let(:filters_string) { 'category_uuid=deadbeef1' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1')
      end
      context 'that maps to a different name' do
        let(:filters_string) { 'name=Book1'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(simple_name: 'Book1')
      end
      context 'that is mapped as a nested struct' do
        let(:filters_string) { 'fake_nested.name=Book1'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(simple_name: 'Book1')
      end
    end

    context 'by a field or a related model' do
      context 'for a belongs_to association' do
        let(:filters_string) { 'author.name=author2'}
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:author).where('active_authors.name' => 'author2')
      end
      context 'for a has_many association' do
        let(:filters_string) { 'taggings.label=primary' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:taggings).where('active_taggings.label' => 'primary')
      end
      context 'for a has_many through association' do
        let(:filters_string) { 'tags.name=blue' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:tags).where('active_tags.name' => 'blue')
      end
    end

    context 'with a field mapping using a proc' do
      let(:filters_string) { 'name_is_not=Book1' }
      it_behaves_like 'subject_equivalent_to', ActiveBook.where.not(simple_name: 'Book1')
    end

    context 'by multiple fields' do
      context 'adds the where clauses for the top model if fields belong to it' do
        let(:filters_string) { 'category_uuid=deadbeef1&name=Book1' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.where(category_uuid: 'deadbeef1',  simple_name: 'Book1')
      end
      context 'adds multiple where clauses for same nested relationship join (instead of multiple joins with 1 clause each)' do
        let(:filters_string) { 'taggings.label=primary&taggings.tag_id=2' }
        it_behaves_like 'subject_equivalent_to', ActiveBook.joins(:taggings).where('active_taggings.label' => 'primary', 'active_taggings.tag_id' => 2)
      end
    end
  end
end
