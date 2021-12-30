# frozen_string_literal: true

require 'spec_helper'

require 'praxis/extensions/attribute_filtering'

describe Praxis::Extensions::AttributeFiltering::FilterTreeNode do
  let(:dummy_object) { double('Fake NodeObject') }
  let(:filters) do
    [
      { name: 'one', op: '>', value: 1, node_object: dummy_object },
      { name: 'one', op: '<', value: 10 },
      { name: 'rel1.a1', op: '=', value: 1 },
      { name: 'rel1.a2', op: '=', value: 2 },
      { name: 'rel1.rel2.b1', op: '=', value: 11 },
      { name: 'rel1.rel2.b2', op: '=', value: 12, node_object: dummy_object }
    ]
  end
  context 'initialization' do
    subject { described_class.new(filters) }
    it 'holds the top conditions and the child in a TreeNode' do
      expect(subject.path).to eq([])
      expect(subject.conditions.size).to eq(2)
      expect(subject.conditions.map { |i| i.slice(:name, :op, :value) }).to eq([
                                                                                 { name: 'one', op: '>', value: 1 },
                                                                                 { name: 'one', op: '<', value: 10 }
                                                                               ])
      expect(subject.children.keys).to eq(['rel1'])
      expect(subject.children['rel1']).to be_kind_of(described_class)
    end

    it 'passes on any node_object value at any level' do
      expect(subject.conditions.first[:node_object]).to be(dummy_object)
      expect(subject.conditions[1]).to_not have_key(:node_object)
      expect(subject.children['rel1'].children['rel2'].conditions[1][:node_object]).to be(dummy_object)
    end

    it 'recursively holds the conditions and the children of their children in a TreeNode' do
      rel1 = subject.children['rel1']
      expect(rel1.path).to eq(['rel1'])
      expect(rel1.conditions.size).to eq(2)
      expect(rel1.conditions.map { |i| i.slice(:name, :op, :value) }).to eq([
                                                                              { name: 'a1', op: '=', value: 1 },
                                                                              { name: 'a2', op: '=', value: 2 }
                                                                            ])
      expect(rel1.children.keys).to eq(['rel2'])
      expect(rel1.children['rel2']).to be_kind_of(described_class)

      rel1rel2 = rel1.children['rel2']
      expect(rel1rel2.path).to eq(%w[rel1 rel2])
      expect(rel1rel2.conditions.size).to eq(2)
      expect(rel1rel2.conditions.map { |i| i.slice(:name, :op, :value) }).to eq([
                                                                                  { name: 'b1', op: '=', value: 11 },
                                                                                  { name: 'b2', op: '=', value: 12 }
                                                                                ])
      expect(rel1rel2.children.keys).to be_empty
    end
  end
end
