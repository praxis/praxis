require 'spec_helper'

describe Praxis::Extensions::Rendering do

  let(:test_class) do
    Struct.new(:media_type, :expanded_fields, :response) do |klass|
      include Praxis::Extensions::Rendering
    end
  end

  let(:media_type) { Person }
  let(:expanded_fields) { {id: true, name: true} }
  let(:response) { double('response', headers: {}) }

  let(:object) { {id: 1, name: 'bob', href: '/people/bob'} }
  subject(:instance) { test_class.new(media_type, expanded_fields, response) }

  context '#render' do
    subject(:output) { instance.render(object) }
    it 'loads and renders the object' do
      expect(output).to eq(id: 1, name: 'bob')
    end
  end

  context '#display' do
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

end
