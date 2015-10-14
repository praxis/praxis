require 'spec_helper'

require 'praxis/extensions/field_selection'

describe Praxis::Extensions::FieldSelection::FieldSelector do

  let(:type) { described_class.for(Address) }


  subject(:field_selector) { type.load(fields) }

  context '.example' do
    subject(:example) { type.example }

    it 'generates a list of 3 random attribute names' do
      example_attributes = example.fields.keys
      expect(example_attributes).to have(3).items
      expect(example_attributes - Address.attributes.keys).to be_empty
    end

    it 'validates' do
      expect(type.example.validate).to be_empty
    end

  end

  context '.load' do
    let(:parsed_fields) { double('fields') }

    it 'loads nil and an empty string as true' do
      expect(type.load(nil).fields).to be(true)
      expect(type.load('').fields).to be(true)
    end


    it 'loads fields' do
      fields = 'id,name,owner(name)'

      expect(Attributor::FieldSelector).to receive(:load).
        with(fields).and_return(parsed_fields)

      result = type.load(fields)
      expect(result.fields).to be parsed_fields
    end

  end

  context '#dump' do
    it 'dumps nested fields properly' do
      fields = 'id,name,owner(name)'
      result = type.load(fields)
      expect(result.dump).to eq fields
    end

    it 'dumps a nil or "" value as ""' do
      expect(type.load(nil).dump).to eq ''
      expect(type.load('').dump).to eq ''
    end
  end
  context '.validate' do
    let(:selector_string) { 'id,name' }
    it 'loads and calls the instance' do
      example = double('example')
      expect(type).to receive(:load).with(selector_string, ['$']).and_return(example)
      expect(example).to receive(:validate).and_return([])
      type.validate(selector_string)
    end
  end

  context '#validate' do
    it do
      expect(type.validate('id,name')).to be_empty
      expect(type.validate('id,state')).to have(1).items
      expect(type.validate('id,owner(name)')).to have(0).items
      expect(type.validate('id,owner(foo)')).to have(1).items
    end
  end



end
