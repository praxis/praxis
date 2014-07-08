require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Praxis::ResourceDefinition do
  subject(:resource_definition) { PeopleResource }

  its(:description) { should eq('People resource') }
  its(:media_type) { should eq(Person) }

  its(:responses) { should eq(Set.new) }
  its(:response_groups) { should eq(Set[:default]) }
  its(:version) { should eq('1.0') }

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

    it 'sets responses' do
      resource_definition.responses(:some_response)
      expect(resource_definition.responses).to eq(Set[:some_response])
    end

    it 'sets response_groups' do
      resource_definition.response_groups(:some_group)
      expect(resource_definition.response_groups).to eq(Set[:default, :some_group])
    end

    it "sets params" do
      resource_definition.params &some_proc

      expect(resource_definition.params[0]).to eq(Attributor::Struct)
      expect(resource_definition.params[1].class).to eq(Hash)
      expect(resource_definition.params[2]).to be(some_proc)
    end

    it "sets payload" do
      resource_definition.payload(some_hash, &some_proc)

      expect(resource_definition.payload[0]).to eq(Attributor::Struct)
      expect(resource_definition.payload[1].class).to eq(Hash)
      expect(resource_definition.payload[2]).to be(some_proc)
    end

    it "sets headersheaders" do
      resource_definition.headers(some_hash, &some_proc)

      expect(subject.headers[0]).to be(some_hash)
      expect(subject.headers[1]).to be(some_proc)
    end

  end


  context '.use' do
    subject(:resource_definition) { Class.new {include Praxis::ResourceDefinition } }
    it 'raises an error for missing traits' do
      expect { resource_definition.use(:stuff) }.
        to raise_error(/Trait .* not found in the system/)
    end
    it 'has a spec for actually using a trait'
  end

end