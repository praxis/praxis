require 'spec_helper'

describe Praxis::ResourceDefinition do
  subject(:resource_definition) { PeopleResource }

  its(:description) { should eq('People resource') }
  its(:media_type) { should eq(Person) }

  its(:version) { should eq('1.0') }
  its(:version_options) { should eq({using: [:header,:params]}) }

  its(:routing_config) { should be_kind_of(Proc) }

  its(:actions) { should have(2).items }



  context '.describe' do
    subject(:describe) { resource_definition.describe }

    its([:description]) { should eq(resource_definition.description) }
    its([:media_type]) { should eq(resource_definition.media_type.name) }

    its([:actions]) { should have(2).items }
  end

  context '.action' do
    it 'requires a block' do
      expect { resource_definition.action(:something)
               }.to raise_error(ArgumentError)
    end
    it 'creates an ActionDefinition for actions' do
      index = resource_definition.actions[:index]
      expect(index).to be_kind_of(Praxis::ActionDefinition)
      expect(index.description).to eq("index description")
    end
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

    its(:version_options){ should be_kind_of(Hash) }

  end


  context '.use' do
    subject(:resource_definition) { Class.new {include Praxis::ResourceDefinition } }
    it 'raises an error for missing traits' do
      expect { resource_definition.use(:stuff) }.to raise_error(Praxis::Exceptions::InvalidTrait)
    end
    it 'has a spec for actually using a trait'
  end


  context 'deprecated action methods' do
    subject(:resource_definition) do
      Class.new do
        include Praxis::ResourceDefinition

        def self.name
          'FooBar'
        end
        silence_warnings do
          payload { attribute :inherited_payload, String }
          headers { header "Inherited-Header", String }
          params  { attribute :inherited_params, String }
          response :not_found
        end

        action :index do
        end
      end
    end

    let(:action) { resource_definition.actions[:index] }

    it 'defers the values to procs in action_defaults' do
      expect(resource_definition.action_defaults).to have(4).items
    end

    it 'delegates defaults to the action' do
      expect(action.payload.attributes).to have_key(:inherited_payload)
      expect(action.headers.attributes).to have_key("Inherited-Header")
      expect(action.params.attributes).to have_key(:inherited_params)
      expect(action.responses).to have_key(:not_found)
    end

  end

  context 'with nodoc! option' do
    before do
      resource_definition.nodoc!      
    end

    it 'has the :doc_visibility set' do
      expect(resource_definition.options[:doc_visibility]).to be(:nodoc)
    end

  end

end
