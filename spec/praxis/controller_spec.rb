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


end
