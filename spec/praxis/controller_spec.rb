# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Controller do
  subject do
    Class.new do
      include Praxis::Controller

      implements PeopleResource

      before :validate, actions: [:index] do
        'before'
      end

      before actions: [:show] do
      end

      after :response, actions: [:show] do
        'after'
      end

      def index; end

      def show; end

      def self.to_s
        'SomeController'
      end
    end
  end

  context '.implements' do
    it 'set the resource definition controller' do
      expect(subject).to eq(PeopleResource.controller)
    end
  end

  describe '#inspect' do
    it 'includes name, object ID and request' do
      expect(subject.new('eioio').inspect).to match(
        /#<SomeController#[0-9]+ @request="eioio">/
      )
    end
  end
end
