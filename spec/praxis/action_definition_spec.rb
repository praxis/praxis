require './lib/praxis'

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
      headers { header :inherited, String }
      params  { attribute :inherited, String }
    end
  end

  subject do
    described_class.new('foo', resource_definition) do
      payload { attribute :two, String }
      headers { header :X_REQUESTED_WITH, 'XMLHttpRequest' }
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
    its('headers.attributes')  { should have_key :X_REQUESTED_WITH }
    its('headers.attributes')  { should have_key :INHERITED }
  end

  context '#responses' do
    it 'sets and returns responses' do
      subject.responses 'one', 'two'
      subject.responses 'three'
      expect(subject.responses).to eq Set.new(['one', 'two', 'three'])
    end
  end

  context '#response_groups' do
    it 'sets and returns response groups' do
      subject.response_groups 'one', 'two'
      subject.response_groups 'three'
      expect(subject.response_groups).to eq Set.new(['one', 'two', 'three'])
    end
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
    it 'merges in more headers' do
      subject.headers do
        header :more
      end

      expect(subject.headers.attributes.keys).to match_array([
        :X_REQUESTED_WITH, :INHERITED, :MORE
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
end
