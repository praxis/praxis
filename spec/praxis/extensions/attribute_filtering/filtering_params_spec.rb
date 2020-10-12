require 'spec_helper'

require 'praxis/extensions/attribute_filtering'

describe Praxis::Extensions::AttributeFiltering::FilteringParams do

  context 'FilterTreeNode' do
    let(:filters) do
      [
        {name: 'one', specs: { op: '>', value: 1}},
        {name: 'one', specs: { op: '<', value: 10}},
        {name: 'rel1.a1', specs: { op: '=', value: 1}},
        {name: 'rel1.a2', specs: { op: '=', value: 2}},
        {name: 'rel1.rel2.b1', specs: { op: '=', value: 11}},
        {name: 'rel1.rel2.b2', specs: { op: '=', value: 12}}
      ]
    end
    subject { described_class::FilterTreeNode.new(filters) }
    it 'holds the top conditions and the child in a TreeNode' do
      expect(subject.conditions.size).to eq(2)
      expect(subject.children.keys).to eq(['rel1'])
      expect(subject.children['rel1']).to be_kind_of(described_class::FilterTreeNode)
    end

    it 'recursively holds the conditions and the children of their children in a TreeNode' do
      rel1 = subject.children['rel1']
      expect(rel1.conditions.size).to eq(2)
      expect(rel1.children.keys).to eq(['rel2'])
      expect(rel1.children['rel2']).to be_kind_of(described_class::FilterTreeNode)

      rel1rel2 = rel1.children['rel2']
      expect(rel1rel2.conditions.size).to eq(2)
      expect(rel1rel2.children.keys).to be_empty
    end
  end
end
