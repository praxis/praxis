# frozen_string_literal: true

require 'spec_helper'

class SpecMediaType < Praxis::MediaType
  identifier 'application/json'

  attributes do
    attribute :one, String
    attribute :two, Integer
  end
  default_fieldset do
    attribute :one
  end
end

describe Praxis::ActionDefinition do
  let(:endpoint_definition) do
    Class.new do
      include Praxis::EndpointDefinition

      def self.name
        'FooBar'
      end

      media_type SpecMediaType
      version '1.0'
      prefix '/foobars/hello_world'
      action_defaults do
        payload { attribute :inherited, String }
        headers { header 'Inherited', String }
        params  { attribute :inherited, String }
      end
    end
  end

  subject(:action) do
    Praxis::ApiDefinition.define do |api|
      api.response_template :ok do |media_type:, location: nil, headers: nil, description: nil|
        status 200

        media_type media_type
        location location
        description description
        headers&.each do |(name, value)|
          header(name, value)
        end
      end
    end
    Praxis::ActionDefinition.new(:foo, endpoint_definition) do
      routing { get '/:one' }
      payload { attribute :two, String }
      headers { header 'X_REQUESTED_WITH', 'XMLHttpRequest' }
      params  { attribute :one, String }
      response :ok, headers: { 'Foo' => 'Bar' }, location: %r{/some/thing}
    end
  end

  context '#initialize' do
    its('name')                { should eq :foo }
    its('endpoint_definition') { should be endpoint_definition }
    its('params.attributes')   { should have_key :one }
    its('params.attributes')   { should have_key :inherited }
    its('payload.attributes')  { should have_key :two }
    its('payload.attributes')  { should have_key :inherited }
    its('headers.attributes')  { should have_key 'X_REQUESTED_WITH' }
    its('headers.attributes')  { should have_key 'Inherited' }
    its('metadata') { should_not have_key :doc_visibility }
  end

  context '#responses' do
    subject(:responses) { action.responses }
    before do
      action.response :ok
      action.response :internal_server_error
      action.response :created, location: 'foobar'
    end

    it { should be_kind_of Hash }
    it { should include :ok }
    it { should include :internal_server_error }
    it { should include :created }
  end

  describe 'when a trait is used' do
    subject(:action) do
      Praxis::ActionDefinition.new(:bar, endpoint_definition) do
        trait :test
        routing { get '/:one' }
        params  { attribute :one, String }
      end
    end

    let(:trait) do
      Praxis::Trait.new do
        routing do
          prefix '/test_trait/:app_name'
        end

        params do
          attribute :app_name, String
          attribute :name, String
        end
      end
    end
    let(:traits) { { test: trait } }

    before do
      allow(Praxis::ApiDefinition.instance).to receive(:traits).and_return(traits)
    end

    its('params.attributes.keys') { should eq %i[inherited app_name name one] }
    its('route.path.to_s') { should eq '/api/foobars/hello_world/test_trait/:app_name/:one' }
    its(:traits) { should eq [:test] }

    it 'is reflected in the describe output' do
      expect(action.describe[:traits]).to eq [:test]
    end
  end

  describe '#params' do
    it 'defaults to being required if omitted' do
      expect(subject.params.options[:required]).to be(true)
    end

    it 'merges in more params' do
      subject.params do
        attribute :more, Attributor::Integer
      end

      attributes = subject.params.attributes.keys
      expect(attributes).to match_array(%i[one inherited more])
    end

    it 'merges options (which allows overriding)' do
      expect(subject.params.options[:required]).to be(true)

      subject.params required: false

      expect(subject.params.options[:required]).to be(false)
    end

    context 'advanced requirements' do
      before do
        action.params do
          attribute :two
          # requires.at_most(1).of :one, :two
          requires :one
        end
      end

      let(:value) { { two: 2 } }
      it 'includes the requirements in the param struct type' do
        errors = action.params.load(value).validate
        expect(errors).to have(1).item
        expect(errors.first).to match('Attribute $.key(:one) is required.')
      end
    end
  end

  describe '#payload' do
    it 'defaults to being required and non nullable if omitted' do
      expect(subject.payload.options[:required]).to be(true)
      expect(subject.payload.options[:null]).to be(false)
    end

    it 'merges in more payload' do
      subject.payload do
        attribute :more, Attributor::Integer
      end

      expect(subject.payload.attributes.keys).to match_array(%i[
                                                               two inherited more
                                                             ])
    end

    it 'merges options (which allows overriding)' do
      expect(subject.payload.options[:required]).to be(true)

      subject.payload required: false

      expect(subject.payload.options[:required]).to be(false)
    end
  end

  describe '#headers' do
    it 'is backed by a Hash' do
      expect(subject.headers.type < Attributor::Hash).to be(true)
    end

    it 'is has case_sensitive_load enabled' do
      expect(subject.headers.type.options[:case_insensitive_load]).to be(true)
    end

    it 'defaults to being required if omitted' do
      expect(subject.headers.options[:required]).to be(true)
    end

    it 'merges in more headers' do
      subject.headers do
        header 'more'
      end

      expected_array = %w[X_REQUESTED_WITH Inherited more]
      expect(subject.headers.attributes.keys).to match_array(expected_array)
    end

    it 'merges options (which allows overriding)' do
      expect(subject.headers.options[:required]).to be(true)

      subject.headers required: false do
        header 'even_more'
      end

      expect(subject.headers.options[:required]).to be(false)
    end
  end

  context '#routing' do
    context 'with a parent specified' do
      let(:resource) { ApiResources::VolumeSnapshots }
      subject(:action) { resource.actions[:show] }

      let(:parent_param) { ApiResources::Volumes.actions[:show].params.attributes[:id] }

      it 'has the right path' do
        expect(action.route.path.to_s).to eq '/api/clouds/:cloud_id/volumes/:volume_id/snapshots/:id'
      end

      its('params.attributes') { should have_key(:cloud_id) }

      context 'with pre-existing parent param' do
        let(:action) { resource.actions[:index] }
        subject(:param) { action.params.attributes[:volume_id] }
        its(:options) { should_not eq parent_param.options }
      end

      context 'with auto-generated param' do
        subject(:param) { action.params.attributes[:volume_id] }
        it { should_not be nil }
        its(:options) { should eq parent_param.options }
      end
    end
  end

  context '#description' do
    it 'sets and returns the description' do
      subject.description('weeeeee')
      expect(subject.description).to eq 'weeeeee'
    end
  end

  context '#describe' do
    subject(:describe) { action.describe }

    context 'params' do
      subject(:param_description) { describe[:params] }
      it 'includes attribute sources' do
        attributes = param_description[:type][:attributes]
        expect(attributes[:inherited][:source]).to eq('query')
        expect(attributes[:one][:source]).to eq('url')
      end
    end

    context 'responses' do
      subject(:response_description) { describe[:responses] }
      its(:keys) { should include(:ok) }
    end
  end

  context 'href generation' do
    let(:endpoint_definition) { ApiResources::Instances }
    subject(:action) { endpoint_definition.actions[:show] }

    it 'works' do
      expansion = action.route.path.expand(cloud_id: '232', id: '2')
      expect(expansion).to eq '/api/clouds/232/instances/2'
    end
  end

  context 'with nodoc!' do
    before do
      action.nodoc!
    end

    it 'has :doc_visibility set in metadata' do
      expect(action.metadata[:doc_visibility]).to be(:none)
    end

    it 'is exposed by describe' do
      expect(action.describe[:metadata][:doc_visibility]).to be(:none)
    end
  end

  context 'enable_large_params_proxy_action' do
    it 'exposes the add_post_equivalent boolean' do
      subject.instance_eval do
        enable_large_params_proxy_action
      end
      expect(subject.sister_post_action).to be_truthy
    end
    it 'does NOT expose the add_post_equivalent boolean when enable_large_params_proxy_action is not called' do
      expect(subject).to_not receive(:enable_large_params_proxy_action)
      expect(subject.sister_post_action).to be_nil
    end
  end

  context 'creating a duplicate action with POST' do
    let(:action) { PeopleResource.actions[:show] }
    let(:post_action_path) { action.route.path.to_s + "/actions/#{action.name}" }
    subject { action.clone_action_as_post(at: post_action_path) }

    it 'changes the route to a post and well-known route' do
      route = subject.route
      expect(route.verb).to eq('POST')
      expect(route.path.to_s).to eq(post_action_path)
    end
    it 'sets the name postfixed with "with_post"' do
      expect(subject.name).to eq("#{action.name}_with_post".to_sym)
    end

    it 'sets the payload to contain all the original param ones, except the required URL ones' do
      expect(subject.payload.attributes.keys).to eq(action.params.attributes.keys - [:id])
      expect(subject.params.attributes.keys).to eq([:id])
    end

    it 'keeps the same headers and response definitions' do
      expect(subject.headers).to eq(action.headers)
      expect(subject.responses).to eq(action.responses)
    end

    it 'links the get and post sister actions appropriately' do
      expect(subject.sister_get_action).to be(action)
      expect(action.sister_post_action).to be(subject)
    end
  end

  context 'with a base_path and base_params on ApiDefinition' do
    # Without getting a fresh new ApiDefinition it is very difficult to test stuff using the Singleton
    # So for some tests we're gonna create a new instance and work with it to avoid the singleton issues
    let(:non_singleton_api) do
      api_def = Praxis::ApiDefinition.__send__(:new)
      api_def.instance_eval do |api|
        api.info do
          base_path '/apps/:app_name'
        end

        api.info '1.0' do
          base_params do
            attribute :app_name, String
          end
        end
      end
      api_def
    end

    before do
      allow(Praxis::ApiDefinition).to receive(:instance).and_return(non_singleton_api)
    end

    its('route.path.to_s') { should eq '/apps/:app_name/foobars/hello_world/:one' }
    its('params.attributes.keys') { should match_array %i[inherited app_name one] }

    context 'where the action overrides a base_param' do
      let(:endpoint_definition) do
        Class.new do
          include Praxis::EndpointDefinition

          def self.name
            'FooBar'
          end
          version '1.0'
          prefix '/foobars/hello_world'
          action_defaults do
            payload { attribute :inherited, String }
            headers { header 'Inherited', String }
          end
        end
      end

      let(:action) do
        Praxis::ActionDefinition.new(:foo, endpoint_definition) do
          routing { get '' }
          params  { attribute :app_name, Integer }
        end
      end

      subject(:attributes) { action.params.attributes }

      its(:keys) { should eq [:app_name] }

      it 'overrides the base param' do
        expect(attributes[:app_name].type).to eq(Attributor::Integer)
      end
    end
  end
end
