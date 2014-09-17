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

end
