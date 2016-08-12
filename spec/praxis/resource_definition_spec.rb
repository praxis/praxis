require 'spec_helper'

describe Praxis::ResourceDefinition do
  subject(:resource_definition) { PeopleResource }

  its(:description) { should eq('People resource') }
  its(:media_type) { should eq(Person) }

  its(:version) { should eq('1.0') }

  its(:prefix) { should eq('/people') }

  its(:actions) { should have(2).items }
  its(:metadata) { should_not have_key(:doc_visibility) }

  context '.describe' do
    subject(:describe) { resource_definition.describe }

    its([:description]) { should eq(resource_definition.description) }
    its([:media_type]) { should eq(resource_definition.media_type.describe(true)) }

    its([:actions]) { should have(2).items }
    its([:metadata]) { should be_kind_of(Hash) }
    its([:traits]) { should eq [:test] }
    it { should_not have_key(:parent)}

    context 'for a resource with a parent' do
      let(:resource_definition) { ApiResources::VolumeSnapshots}

      its([:parent]) { should eq ApiResources::Volumes.id }
    end

  end


  context '.routing_prefix' do
    subject(:resource_definition) { ApiResources::VolumeSnapshots }
    it do
      expect(resource_definition.routing_prefix).to eq('/clouds/:cloud_id/volumes/:volume_id/snapshots')
    end
  end

  context '.parent_prefix' do
    subject(:resource_definition) { ApiResources::VolumeSnapshots }
    let(:base_path){ Praxis::ApiDefinition.instance.info.base_path }
    its(:parent_prefix){ should eq('/clouds/:cloud_id/volumes/:volume_id') }
    it do
      expect(resource_definition.parent_prefix).to_not match(/^#{base_path}/)
    end
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

    it 'complains if action names are not symbols' do
      expect do
        Class.new do
          include Praxis::ResourceDefinition
          action "foo" do
          end
        end
      end.to raise_error(ArgumentError,/Action names must be defined using symbols/)
    end
  end

  context 'action_defaults' do
    let(:resource_definition) do
      Class.new do
        include Praxis::ResourceDefinition
        media_type Person

        version '1.0'
        def self.name
          'FooBar'
        end

        action_defaults do
          routing do
            prefix '/people/:id'
          end

          params do
            attribute :id
          end
        end

        action :show do
          routing do
            get ''
          end
        end

      end
    end

    let(:non_singleton_api) do
      api_def=Praxis::ApiDefinition.__send__(:new)
      api_def.instance_eval do |api|

        api.info do
          base_path '/api/:base_param'
          base_params do
            attribute :base_param, String
            attribute :grouped_params do
              attribute :nested_param, String
            end
          end
        end

        api.info '1.0' do
          base_params do
            attribute :app_name, String
          end
        end
        api.info '2.0' do
          base_params do
            attribute :v2_param, String
          end
        end
      end
      api_def
    end

    before do
      allow(Praxis::ApiDefinition).to receive(:instance).and_return(non_singleton_api)
    end

    it 'are applied to actions' do
      action = resource_definition.actions[:show]
      expect(action.params.attributes).to have_key(:id)
      expect(action.routes.first.path.to_s).to eq '/api/:base_param/people/:id'
    end

    context 'includes base_params from the APIDefinition' do
      let(:show_action_params){ resource_definition.actions[:show].params }

      it 'including globally defined' do
        expect(show_action_params.attributes).to have_key(:base_param)
        expect(show_action_params.attributes).to have_key(:grouped_params)
        grouped = show_action_params.attributes[:grouped_params]
        expect(grouped.type.ancestors).to include(::Attributor::Struct)
        expect(grouped.type.attributes.keys).to eq([:nested_param])
      end
      it 'including the ones defined for its own version' do
        expect(show_action_params.attributes).to have_key(:app_name)
        expect(show_action_params.attributes).to_not have_key(:v2_param)
      end

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


  context '.trait' do
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
          headers { key "Inherited-Header", String }
          params  { attribute :inherited_params, String }
          response :not_found
        end

        action :index do
        end
      end
    end

    let(:action) { resource_definition.actions[:index] }

    it 'are applied to the action' do
      expect(action.payload.attributes).to have_key(:inherited_payload)
      expect(action.headers.attributes).to have_key("Inherited-Header")
      expect(action.params.attributes).to have_key(:inherited_params)
      expect(action.responses).to have_key(:not_found)
    end

  end

  context 'with nodoc! called' do
    before do
      resource_definition.nodoc!
    end

    it 'has the :doc_visibility option set' do
      expect(resource_definition.metadata[:doc_visibility]).to be(:none)
    end

    it 'is exposed in the describe' do
      expect(resource_definition.describe[:metadata][:doc_visibility]).to be(:none)
    end

  end

  context '#canonical_path' do
    context 'setting the action' do
      it 'reads the specified action' do
        expect(subject.canonical_path).to eq(subject.actions[:show])
      end
      it 'cannot be done if already been defined' do
        expect{
          resource_definition.canonical_path :reset
        }.to raise_error(/'canonical_path' can only be defined once./)
      end
    end
    context 'if none specified' do
      subject(:resource_definition) do
        Class.new do
          include Praxis::ResourceDefinition
          action :show do
          end
        end
      end
      it 'defaults to the :show action' do
        expect(subject.canonical_path).to eq(subject.actions[:show])
      end
    end
    context 'with an undefined action' do
      subject(:resource_definition) do
        Class.new do
          include Praxis::ResourceDefinition
          canonical_path :non_existent
        end
      end
      it 'raises an error' do
        expect{
          subject.canonical_path
        }.to raise_error(/Action 'non_existent' does not exist/)
      end
    end
  end

  context '#to_href' do
    it 'accesses the path expansion functions of the primary route' do
      expect(subject.to_href( id: 1)).to eq("/people/1")
    end
  end
  context '#parse_href' do
    let(:parsed){ resource_definition.parse_href("/people/1") }
    it 'accesses the path expansion functions of the primary route' do
      expect(parsed).to have_key(:id)
    end
    it 'coerces the types as specified in the resource definition' do
      expect(parsed[:id]).to be_kind_of(Integer)
    end
  end

end
