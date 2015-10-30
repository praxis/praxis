require 'spec_helper'


describe Praxis::Responses::ValidationError do

  let(:summary){ "Something happened here" }
  context 'a basic response' do
    subject(:response) { Praxis::Responses::ValidationError.new(summary: summary, errors: []) }
    it 'always sets the json content type' do
      expect(response.name).to be(:validation_error)
      expect(response.status).to be(400)
      expect(response.body).to be_empty
      expect(response.headers).to have_key('Content-Type')
      expect(response.headers['Content-Type']).to eq('application/json')
      expect(response.instance_variable_get(:@errors)).to eq([])
      expect(response.instance_variable_get(:@exception)).to be(nil)
    end
  end

  context '.format!' do
    let(:errors) { [1,2] }
    let(:cause){ Exception.new( "cause message") }
    let(:exception_message){ "exception message" }
    let(:exception){ nil }
    subject(:response) { Praxis::Responses::ValidationError.new(summary: summary, errors: errors, exception: exception) }
    before do
      expect(response.body).to be_empty
    end

    it 'it fills the errors key' do
      response.format!
      expect(response.body).to eq({name: 'ValidationError', summary: summary, errors: errors})
    end

    context 'with an exception' do
      let(:exception){ double("exception", message: exception_message, cause: cause)}
      before do
         response.format!
         expect(response.body.keys).to include(:name,:summary)
         expect(response.body[:name]).to eq('ValidationError')
         expect(response.body[:summary]).to eq(summary)
      end

      context 'without cause' do
        let(:cause){ nil}
        it 'does not include it in the output' do
          expect(response.body).to_not have_key(:cause)
        end
      end

      context 'with a cause' do
        it 'it fills the cause too' do
          expect(response.body).to have_key(:cause)
          expect(response.body[:cause]).to eq({name: cause.class.name, message: cause.message })
        end
      end
    end

  end

  context 'its response template' do
    let(:template){ Praxis::ApiDefinition.instance.responses[:validation_error] }
    it 'is registered with the ApiDefinition' do
      expect(template).to be_kind_of(Praxis::ResponseTemplate)
    end
  end
end
