# frozen_string_literal: true

require 'spec_helper'

require 'praxis/extensions/field_selection'

describe Praxis::Extensions::FieldExpansion do
  # include the ActionDefinitionExtension module directly, as that's where the
  # bulk of lies, and by including this instead of the base FieldExpansion module
  # we avoid the side-effect of injecting the ActionDefinitionExtension into
  # the base Praxis::ActionDefinition.
  let(:test_class) do
    Class.new do
      include Praxis::Extensions::FieldExpansion::ActionDefinitionExtension

      def initialize(params)
        @params = params
      end

      attr_accessor :params
    end
  end

  let(:test_instance) { test_class.new(test_params) }

  let(:request_params) do
    double('params',
           fields: Praxis::Extensions::FieldSelection::FieldSelector.for(Person).load(fields))
  end

  let(:request) { double('Praxis::Request', params: request_params) }
  let(:media_type) { Person }

  let(:fields) { nil }

  let(:test_attributes) {}
  let(:test_params) { double('test_params', attributes: test_attributes) }
  let(:expansion_filter) { nil }
  subject(:expansion) { test_instance.expanded_fields(request, media_type, expansion_filter) }

  context '#expanded_fields' do
    context 'with fields and view params defined' do
      let(:test_attributes) { {} }

      context 'with no fields provided' do
        it 'returns the fields for the default view' do
          expect(expansion).to eq({ id: true, name: true })
        end
      end

      context 'with a set of fields provided' do
        let(:fields) { 'id,name,owner{name}' }
        it 'returns the subset of fields' do
          expected = { id: true, name: true }
          expect(expansion).to eq expected
        end
      end
    end

    context 'with an action with no params' do
      let(:test_params) { nil }
      it 'ignores incoming parameters and expands for the default fieldset' do
        expect(expansion).to eq({ id: true, name: true })
      end
    end
  end
end
