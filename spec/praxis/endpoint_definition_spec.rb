# frozen_string_literal: true

require 'spec_helper'

describe Praxis::EndpointDefinition do
  subject(:endpoint_definition) { PeopleResource }

  its(:description) { should eq('People resource') }
  its(:media_type) { should eq(Person) }

  its(:version) { should eq('1.0') }

  its(:prefix) { should eq('/people') }

  its(:actions) { should have(4).items } # Two real actions, and two post versions of the GET
  its(:metadata) { should_not have_key(:doc_visibility) }

  context '.describe' do
    subject(:describe) { endpoint_definition.describe }

    its([:description]) { should eq(endpoint_definition.description) }
    its([:media_type]) { should eq(endpoint_definition.media_type.describe(true)) }

    its([:actions]) { should have(4).items }  # Two real actions, and two post versions of the GET
    its([:metadata]) { should be_kind_of(Hash) }
    its([:traits]) { should eq [:test] }
    it { should_not have_key(:parent) }

    context 'for a resource with a parent' do
      let(:endpoint_definition) { ApiResources::VolumeSnapshots }

      its([:parent]) { should eq ApiResources::Volumes.id }
    end
  end

  context '.routing_prefix' do
    subject(:endpoint_definition) { ApiResources::VolumeSnapshots }
    it do
      expect(endpoint_definition.routing_prefix).to eq('/clouds/:cloud_id/volumes/:volume_id/snapshots')
    end
  end

  context '.parent_prefix' do
    subject(:endpoint_definition) { ApiResources::VolumeSnapshots }
    let(:base_path) { Praxis::ApiDefinition.instance.info.base_path }
    its(:parent_prefix) { should eq('/clouds/:cloud_id/volumes/:volume_id') }
    it do
      expect(endpoint_definition.parent_prefix).to_not match(/^#{base_path}/)
    end
  end

  context '.action' do
    it 'requires a block' do
      expect do
        endpoint_definition.action(:something)
      end.to raise_error(ArgumentError)
    end
    it 'creates an ActionDefinition for actions' do
      index = endpoint_definition.actions[:index]
      expect(index).to be_kind_of(Praxis::ActionDefinition)
      expect(index.description).to eq('index description')
    end

    it 'complains if action names are not symbols' do
      expect do
        Class.new do
          include Praxis::EndpointDefinition
          action 'foo' do
          end
        end
      end.to raise_error(ArgumentError, /Action names must be defined using symbols/)
    end
    context 'enable_large_params_proxy_action' do
      it 'duplicates the show action with a sister _with_post one' do
        action_names = endpoint_definition.actions.keys
        expect(action_names).to match_array(%i[index show show_with_post index_with_post])
      end
      context 'defaults the exposed path for the POST action "' do
        it 'to add a prefix of "actions/<action_name' do
          expect(endpoint_definition.actions[:show_with_post].route.verb).to eq('POST')
          expect(endpoint_definition.actions[:show_with_post].route.prefixed_path).to eq('/people/:id/actions/show')
        end
      end
      context 'allows to specify the exposed path with the at: argument' do
        it 'will use /people/some/custom/path postfix (cause at: parameter was "some/custom/path")' do
          expect(endpoint_definition.actions[:index_with_post].route.verb).to eq('POST')
          expect(endpoint_definition.actions[:index_with_post].route.prefixed_path).to eq('/people/some/custom/path')
        end
      end

      it 'it sets its payload to match the original action params (except any params in the URL path)' do
        payload_for_show_with_post = endpoint_definition.actions[:show_with_post].payload.attributes
        params_for_show = endpoint_definition.actions[:show].params.attributes
        expect(payload_for_show_with_post.keys).to eq(params_for_show.keys - [:id])
      end
      it 'it sets its params to only contain the the original action params that were in the URL' do
        params_for_show_with_post = endpoint_definition.actions[:show_with_post].params.attributes
        expect(params_for_show_with_post.keys).to eq([:id])
      end
    end
  end

  context 'action_defaults' do
    let(:endpoint_definition) do
      Class.new do
        include Praxis::EndpointDefinition
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
      api_def = Praxis::ApiDefinition.__send__(:new)
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
      action = endpoint_definition.actions[:show]
      expect(action.params.attributes).to have_key(:id)
      expect(action.route.path.to_s).to eq '/api/:base_param/people/:id'
    end

    context 'includes base_params from the APIDefinition' do
      let(:show_action_params) { endpoint_definition.actions[:show].params }

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
    subject(:endpoint_definition) { Class.new { include Praxis::EndpointDefinition } }

    let(:some_proc) { proc {} }
    let(:some_hash) { {} }

    it 'accepts a string as media_type' do
      endpoint_definition.media_type('Something')
      expect(endpoint_definition.media_type).to be_kind_of(Praxis::SimpleMediaType)
      expect(endpoint_definition.media_type.identifier).to eq('Something')
    end

    its(:version_options) { should be_kind_of(Hash) }
  end

  context '.trait' do
    subject(:endpoint_definition) { Class.new { include Praxis::EndpointDefinition } }
    it 'raises an error for missing traits' do
      expect { endpoint_definition.trait(:stuff) }.to raise_error(Praxis::Exceptions::InvalidTrait)
    end
    it 'adds it to its list when it is available in the APIDefinition instance' do
      trait_name = :test
      expect(endpoint_definition.traits).to_not include(trait_name)

      endpoint_definition.trait(trait_name)
      expect(endpoint_definition.traits).to include(trait_name)
    end
  end

  context 'with nodoc! called' do
    before do
      endpoint_definition.nodoc!
    end

    it 'has the :doc_visibility option set' do
      expect(endpoint_definition.metadata[:doc_visibility]).to be(:none)
    end

    it 'is exposed in the describe' do
      expect(endpoint_definition.describe[:metadata][:doc_visibility]).to be(:none)
    end
  end

  context '#canonical_path' do
    context 'setting the action' do
      it 'reads the specified action' do
        expect(subject.canonical_path).to eq(subject.actions[:show])
      end
      it 'cannot be done if already been defined' do
        expect do
          endpoint_definition.canonical_path :reset
        end.to raise_error(/'canonical_path' can only be defined once./)
      end
    end
    context 'if none specified' do
      subject(:endpoint_definition) do
        Class.new do
          include Praxis::EndpointDefinition
          action :show do
          end
        end
      end
      it 'defaults to the :show action' do
        expect(subject.canonical_path).to eq(subject.actions[:show])
      end
    end
    context 'with an undefined action' do
      subject(:endpoint_definition) do
        Class.new do
          include Praxis::EndpointDefinition
          canonical_path :non_existent
        end
      end
      it 'raises an error' do
        expect do
          subject.canonical_path
        end.to raise_error(/Action 'non_existent' does not exist/)
      end
    end
  end

  context '#to_href' do
    it 'accesses the path expansion functions of the primary route' do
      expect(subject.to_href(id: 1)).to eq('/people/1')
    end
  end
  context '#parse_href' do
    let(:parsed) { endpoint_definition.parse_href('/people/1') }
    it 'accesses the path expansion functions of the primary route' do
      expect(parsed).to have_key(:id)
    end
    it 'coerces the types as specified in the resource definition' do
      expect(parsed[:id]).to be_kind_of(Integer)
    end
  end
end
