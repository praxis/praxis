require './lib/praxis'

describe Praxis::ActionDefinition do
  let(:klass) { Praxis::ActionDefinition }

  let(:resource_definition) {
    Class.new do
      include Praxis::ResourceDefinition

      def self.name
        'FooBar'
      end

      media_type 'application/json'
      version '1.0'

      routing do
        prefix '/api/hello_world'
      end

      payload { attribute :inherited, String }
      headers { header :inherited, String }
      params  { attribute :inherited, String }
    end
  }

  subject do
    klass.new('foo', resource_definition) do
      payload do
        attribute :two, String
      end

      headers do
        header :X_REQUESTED_WITH, 'XMLHttpRequest'
      end

      params do
        attribute :one, String
      end
    end
  end

  context '#initialize' do
    it 'sets the name' do
      expect(subject.name).to eq 'foo'
    end

    it 'sets the resource definition' do
      expect(subject.resource_definition).to be resource_definition
    end

    it 'sets params' do
      expect(subject.params.attributes).to have_key(:one)
    end

    it 'inherits params' do
      expect(subject.params.attributes).to have_key(:inherited)
    end

    it 'sets payload' do
      expect(subject.payload.attributes).to have_key(:two)
    end

    it 'inherits payload' do
      expect(subject.payload.attributes).to have_key(:inherited)
    end

    it 'sets headers' do
      expect(subject.headers.attributes).to have_key :X_REQUESTED_WITH
    end

    it 'inherits headers' do
      expect(subject.headers.attributes).to have_key :INHERITED
    end
  end

  context '#responses' do
    it 'has no responses initially' do
      expect(subject.responses).to eq Set.new
    end

    it 'sets a response' do
      subject.responses 'one'
      expect(subject.responses).to eq Set.new(['one'])
    end

    it 'sets two responses' do
      subject.responses 'one', 'two'
      expect(subject.responses).to eq Set.new(['one', 'two'])
    end

    it 'sets two responses, then another' do
      subject.responses 'one', 'two'
      subject.responses 'three'
      expect(subject.responses).to eq Set.new(['one', 'two', 'three'])
    end
  end

  context '#response_groups' do
    it 'has no response_groups initially' do
      expect(subject.response_groups).to eq Set.new
    end

    it 'sets a response' do
      subject.response_groups 'one'
      expect(subject.response_groups).to eq Set.new(['one'])
    end

    it 'sets two response_groups' do
      subject.response_groups 'one', 'two'
      expect(subject.response_groups).to eq Set.new(['one', 'two'])
    end

    it 'sets two response_groups, then another' do
      subject.response_groups 'one', 'two'
      subject.response_groups 'three'
      expect(subject.response_groups).to eq Set.new(['one', 'two', 'three'])
    end
  end

  describe '#allowed_responses' do
    # TODO: add tests after we get a new interface to ApiDefinition.instance
  end

  describe '#use' do
    # TODO: add tests after we get a new interface to ApiDefinition.instance
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
    # TODO: write this test when Skeletor::RestfulRoutingConfig disappears
  end

  context '#description' do
    it 'sets and returns the description' do
      subject.description('weeeeee')
      expect(subject.description).to eq 'weeeeee'
    end
  end

  context '#describe' do
    # TODO: write this test when Skeletor::RestfulRoutingConfig disappears
  end
end
