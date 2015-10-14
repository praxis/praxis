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
      fields: Praxis::Extensions::FieldSelection::FieldSelector.for(Person).load(fields),
      view: view
    )
  end

  let(:request) { double('Praxis::Request', params: request_params) }
  #let(:media_type) { double('Praxis::MediaType') }
  let(:media_type) { Person }

  let(:fields) { nil }
  let(:view) { nil }

  let(:test_attributes) {  }
  let(:test_params) { double('test_params', attributes: test_attributes) }


  subject(:expansion) { test_instance.expanded_fields(request, media_type)}


  context '#expanded_fields' do
    # it 'memoizes the results of expansion' do
    #   binding.pry
    #   expect(field_selector.expand(view)).to be(field_selector.expand(view))
    # end

    context 'with fields and view params defined' do
      let(:test_attributes) { {view: true, fields: true}  }

      context 'and no fields provided' do
        it 'returns the fields for the default view' do
          expect(expansion).to eq({id: true, name: true, links: [true]})
        end

        context 'and a view' do
          let(:view) { :link }
          it 'expands the fields on the view' do
            expect(expansion).to eq({id: true, name: true, href: true})
          end
        end
      end

      context 'with a set of fields provided' do
        let(:fields) { 'id,name,owner(name)' }
        it 'returns the subset of fields for the default view' do
          expected = {id: true, name: true }
          expect(expansion).to eq expected
        end

        context 'and a view' do
          let(:view) { :link }
          let(:fields) { 'id,href' }

          it 'returns the subset of fields that exist for the view' do
            expected = {id: true, href: true }
            expect(expansion).to eq expected
          end
        end
      end
    end

    context 'with only a view param defined' do
      let(:test_attributes) { {fields: true}  }

      it 'returns the fields for the default view' do
        expect(expansion).to eq({id: true, name: true, links: [true]})
      end

      context 'and a view' do
        let(:view) { :link }
        it 'expands the fields on the view' do
          expect(expansion).to eq({id: true, name: true, href: true})
        end
      end
    end
  end

end
