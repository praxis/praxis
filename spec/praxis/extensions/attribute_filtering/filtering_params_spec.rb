require 'spec_helper'

require 'praxis/extensions/attribute_filtering'

describe Praxis::Extensions::AttributeFiltering::FilteringParams do

  context '.load' do
    subject { described_class.load(filters_string) }
    context 'parses for operator' do
      described_class::AVAILABLE_OPERATORS.each do |op|
        it "#{op}" do
          str = "thename#{op}thevalue"
          parsed = [{ name: :thename, op: op, value: 'thevalue'}]
          expect(described_class.load(str).parsed_array).to eq(parsed)
        end
      end
    end
    context 'with all operators at once' do
      let(:filters_string) { 'one=1&two!=2&three>=3&four<=4&five<5&six>6&seven!&eight!!'}
      it do
        expect(subject.parsed_array).to eq([
          { name: :one, op: '=', value: '1'},
          { name: :two, op: '!=', value: '2'},
          { name: :three, op: '>=', value: '3'},
          { name: :four, op: '<=', value: '4'},
          { name: :five, op: '<', value: '5'},
          { name: :six, op: '>', value: '6'},
          { name: :seven, op: '!', value: nil},
          { name: :eight, op: '!!', value: nil},          
        ])
      end
    end
  end
end
