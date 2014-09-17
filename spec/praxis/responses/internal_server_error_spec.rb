require 'spec_helper'


describe Praxis::Responses::InternalServerError do

  context 'a basic response' do
    subject(:response) { Praxis::Responses::InternalServerError.new }
    it 'always sets the json content type' do
      expect(response.name).to be(:internal_server_error)
      expect(response.status).to be(500)
      expect(response.body).to be_empty
      expect(response.headers).to have_key('Content-Type')
      expect(response.headers['Content-Type']).to eq('application/json')
      expect(response.instance_variable_get(:@error)).to be(nil)
    end
  end

  context '.format!' do
    let(:error) { double('error', message: 'error message', backtrace: [1, 2], cause: cause) }
    subject(:response) { Praxis::Responses::InternalServerError.new(error: error) }
    before do
      expect(response.body).to be_empty
      response.format!
    end

    context 'without a cause' do
      let(:cause) { nil }
      it 'it fills message and backtrace' do
        expect(response.body).to eq({name: error.class.name, message: error.message, backtrace: error.backtrace})
      end
    end

    context 'with a cause' do
      let(:cause) { Exception.new('cause message') }
      it 'it fills message, backtrace and cause' do
        expect(response.body.keys).to eq([:name, :message, :backtrace, :cause])
        expect(response.body[:name]).to eq(error.class.name)
        expect(response.body[:message]).to eq(error.message)
        expect(response.body[:backtrace]).to eq(error.backtrace)
        expect(response.body[:cause]).to eq({ name: cause.class.name, message: cause.message, backtrace: cause.backtrace })
      end
    end
  end

  context 'its response template' do
    let(:template){ Praxis::ApiDefinition.instance.responses[:internal_server_error] }
    it 'is registered with the ApiDefinition' do
      expect(template).to be_kind_of(Praxis::ResponseTemplate)
    end
  end
end
