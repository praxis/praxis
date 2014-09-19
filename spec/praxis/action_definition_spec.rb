require 'spec_helper'

describe Praxis::ActionDefinition do
  let(:resource_definition) do
    Class.new do
      include Praxis::ResourceDefinition

      def self.name
        'FooBar'
      end

      media_type 'application/json'
      version '1.0'
      routing { prefix '/api/hello_world' }
      payload { attribute :inherited, String }
      headers { header "Inherited", String }
      params  { attribute :inherited, String }
    end
  end

  subject(:action) do
    described_class.new('foo', resource_definition) do
      routing { get '/:one' }
      payload { attribute :two, String }
      headers { header "X_REQUESTED_WITH", 'XMLHttpRequest' }
      params  { attribute :one, String }
    end
  end

  context '#initialize' do
    its('name')                { should eq 'foo' }
    its('resource_definition') { should be resource_definition }
    its('params.attributes')   { should have_key :one }
    its('params.attributes')   { should have_key :inherited }
    its('payload.attributes')  { should have_key :two }
    its('payload.attributes')  { should have_key :inherited }
    its('headers.attributes')  { should have_key "X_REQUESTED_WITH" }
    its('headers.attributes')  { should have_key "Inherited" }
  end

  context '#responses' do
    subject(:responses) { action.responses }
    before do
      action.response :ok
      action.response :internal_server_error
    end
    
    it { should be_kind_of Hash }
    it { should include :ok }
    it { should include :internal_server_error }
  end

  describe '#allowed_responses' do
    it 'has some tests after we stop using ApiDefinition.instance'
  end

  describe '#use' do
    it 'has some tests after we stop using ApiDefinition.instance'
  end

  describe '#params' do
    it 'merges in more params' do
      subject.params do
        attribute :more, Attributor::Integer
      end

      expect(subject.params.attributes.keys).to match_array([
        :one, :inherited, :more
      ])
    end
  end

  describe '#payload' do
    it 'merges in more payload' do
      subject.payload do
        attribute :more, Attributor::Integer
      end

      expect(subject.payload.attributes.keys).to match_array([
        :two, :inherited, :more
      ])
    end
  end

  describe '#headers' do
    it 'is backed by a Hash' do 
      expect(subject.headers.type < Attributor::Hash).to be(true)
    end

    it 'is has case_sensitive_load enabled' do
      expect(subject.headers.type.options[:case_insensitive_load]).to be(true) 
    end

    it 'merges in more headers' do
      subject.headers do
        header "more"
      end

      expect(subject.headers.attributes.keys).to match_array([
        "X_REQUESTED_WITH", "Inherited", "more"
      ])
    end
  end

  describe '#routing' do
    it 'has some tests when Skeletor::RestfulRoutingConfig disappears'
  end

  context '#description' do
    it 'sets and returns the description' do
      subject.description('weeeeee')
      expect(subject.description).to eq 'weeeeee'
    end
  end

  context '#describe' do
    it 'has some tests when Skeletor::RestfulRoutingConfig disappears'
  end

  context 'href generation' do
    let(:resource_definition) { ApiResources::Instances }
    subject(:action) { resource_definition.actions[:show] }

    it 'works' do
      expansion = action.primary_route.path.expand(cloud_id:232, id: 2)
      expect(expansion).to eq "/clouds/232/instances/2"
    end

    context '#primary_route' do
      it 'is the first-defined route' do
        expect(action.primary_route).to be(action.routes.first)
      end
    end

    context '#named_routes' do
      subject(:named_routes) { action.named_routes }

      its([:alternate]) { should be(action.routes[1]) }
    end

  end
end
