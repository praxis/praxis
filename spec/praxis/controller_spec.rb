require 'spec_helper'

describe Praxis::Controller do
  subject do
    Class.new {
      include Praxis::Controller

      implements PeopleResource

      before :validate, actions: [:index] do
        "before"
      end

      before actions: [:show] do
      end

      after :response, actions: [:show] do
        "after"
      end

      def index
      end

      def show
      end
    }
  end

  context '.implements' do
    it 'set the resource definition controller' do
      expect(subject).to eq(PeopleResource.controller)
    end
  end

  context '.actions' do
    it 'gets the controller actions' do
      expect(subject.actions.keys).to match_array([:index, :show])
      expect(subject.actions[:index]).to be_kind_of(Praxis::ActionDefinition)
      expect(subject.actions[:index].name).to eq(:index)
    end
  end

  context '.action' do
    it 'gets the index action of the controller' do
      expect(subject.action(:index)).to be_kind_of(Praxis::ActionDefinition)
      expect(subject.action(:index).name).to eq(:index)
    end
  end

  context '.before' do
    let(:validate_conditions) { subject.before_callbacks[[:validate]][0][0] }
    let(:validate_block) { subject.before_callbacks[[:validate]][0][1] }

    it 'sets up the before_callbacks' do
      expect(subject.before_callbacks.keys).to match_array([[:validate], [:action]])
      expect(validate_conditions).to eq({:actions => [:index]})
      expect(validate_block).to be_kind_of(Proc)
      expect(validate_block.call(*validate_conditions)).to eq("before")
    end
  end

  context '.after' do
    let(:response_conditions) { subject.after_callbacks[[:response]][0][0] }
    let(:response_block) { subject.after_callbacks[[:response]][0][1] }

    it 'sets up the after_callbacks' do
      expect(subject.after_callbacks.keys).to match_array([[:response]])
      expect(response_conditions).to eq({:actions => [:show]})
      expect(response_block).to be_kind_of(Proc)
      expect(response_block.call(*response_conditions)).to eq("after")
    end
  end
end
