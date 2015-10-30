require 'spec_helper'

describe Praxis::Extensions::Rendering do

  let(:test_class) do
    Struct.new(:media_type, :expanded_fields, :response, :request) do |klass|
      include Praxis::Extensions::Rendering
    end
  end

  let(:media_type) { Person }
  let(:expanded_fields) { {id: true, name: true} }
  let(:response) { double('response', headers: {}) }
  let(:request) { double('request') }

  let(:object) { {id: '1', name: 'bob', href: '/people/bob'} }
  subject(:instance) { test_class.new(media_type, expanded_fields, response, request) }

  context '#render' do
    subject(:output) { instance.render(object) }
    it 'loads and renders the object' do
      expect(output).to eq(id: 1, name: 'bob')
    end
  end

  context '#display' do
    context 'without exception' do
      before do
        expect(response).to receive(:body=).with({id: 1, name: 'bob'})
      end

      subject!(:output) { instance.display(object) }

      it 'returns the response' do
        expect(output).to be(response)
      end

      it 'sets the Content-Type header' do
        expect(response.headers['Content-Type']).to eq 'application/vnd.acme.person'
      end
    end

    context 'with a rendering exception' do
      let(:handler_params) do
        {
          summary: "Circular Rendering Error when rendering response. " +
                 "Please especify a view to narrow the dependent fields, or narrow your field set.",
          exception: circular_exception,
          request: request,
          stage: :action,
          errors: nil
        }
      end
      let(:circular_exception){ Praxis::Renderer::CircularRenderingError.new(object, "ctx") }
      it 'catches a circular rendering exception' do
        expect(instance).to receive(:render).and_raise(circular_exception)
        expect(Praxis::Application.instance.validation_handler).to receive(:handle!).with(handler_params)
        instance.display(object)
      end
    end
  end

end
