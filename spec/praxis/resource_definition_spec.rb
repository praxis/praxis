require 'spec_helper'

describe Praxis::ResourceDefinition do
  subject(:resource_definition) { PeopleResource }

  its(:description) { should eq('People resource') }
  its(:media_type) { should eq(Person) }

  its(:responses) { should eq(Hash.new) }
  its(:version) { should eq('1.0') }
  its(:version_options) { should eq({using: [:header,:params]}) }

  its(:routing_config) { should be_kind_of(Proc) }

  its(:params) { should be_nil }
  its(:payload) { should be_nil }
  its(:headers) { should be_nil }

  its(:actions) { should have(2).items }


  context '.describe' do
    subject(:describe) { resource_definition.describe }

    its([:description]) { should eq(resource_definition.description) }
    its([:media_type]) { should eq(resource_definition.media_type.name) }

    its([:actions]) { should have(2).items }
  end


  it 'creates ActionDefinitions for actions' do
    index = resource_definition.actions[:index]
    expect(index).to be_kind_of(Praxis::ActionDefinition)
    expect(index.description).to eq("index description")
  end


  context 'setting other values' do
    subject(:resource_definition) { Class.new {include Praxis::ResourceDefinition } }

    let(:some_proc) { Proc.new {} }
    let(:some_hash) { Hash.new }

    it 'accepts a string as media_type' do
      resource_definition.media_type('Something')
      expect(resource_definition.media_type).to be_kind_of(Praxis::SimpleMediaType)
      expect(resource_definition.media_type.identifier).to eq('Something')
    end

    context 'sets responses' do
      before do
        resource_definition.response(:some_response)
      end
      subject(:responses){ resource_definition.responses }
      it { should be_kind_of(Hash) }

    end

    context 'setting params' do
      it 'uses the right default values' do
        resource_definition.params &some_proc

        expect(resource_definition.params[0]).to be(Attributor::Struct)
        expect(resource_definition.params[1]).to eq({})
        expect(resource_definition.params[2]).to be(some_proc)
      end

      it 'accepts specific a type and options' do
        resource_definition.params Person, required: true

        expect(resource_definition.params[0]).to be(Person)
        expect(resource_definition.params[1]).to eq({required: true})
        expect(resource_definition.params[2]).to be(nil)
      end
    end


    context 'setting payload' do
      it 'uses the right default values' do
        resource_definition.payload &some_proc

        expect(resource_definition.payload[0]).to be(Attributor::Struct)
        expect(resource_definition.payload[1]).to eq({})
        expect(resource_definition.payload[2]).to be(some_proc)
      end

      it 'accepts specific a type and options' do
        resource_definition.payload Person, required: true

        expect(resource_definition.payload[0]).to be(Person)
        expect(resource_definition.payload[1]).to eq({required: true})
        expect(resource_definition.payload[2]).to be(nil)
      end

    end


    it "sets headers" do
      resource_definition.headers(some_hash, &some_proc)

      expect(subject.headers[0]).to be(some_hash)
      expect(subject.headers[1]).to be(some_proc)
    end

  end


  context '.use' do
    subject(:resource_definition) { Class.new {include Praxis::ResourceDefinition } }
    it 'raises an error for missing traits' do
      expect { resource_definition.use(:stuff) }.to raise_error(Praxis::Exceptions::InvalidTrait)
    end
    it 'has a spec for actually using a trait'
  end

end
