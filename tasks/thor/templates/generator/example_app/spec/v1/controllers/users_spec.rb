# frozen_string_literal: true


require 'spec_helper'
describe V1::Controllers::Users do
  before do
    header 'X-API-Version', '1'
  end

  let(:response) { subject; last_response }
  let(:json_payload) { JSON.dump(payload) }
  let(:parsed_body) { JSON.parse(response.body, symbolize_names: true) }

  context 'index' do
    let(:filters_q) { '' }
    let(:fields_q) { 'uid,uuid' }
    let(:query_string) do
      "filters=#{CGI.escape(filters_q)}&fields=#{CGI.escape(fields_q)}"
    end
    subject { get "/users?#{query_string}" }

    context 'without filters' do
      it { expect(response.status).to eq 200 }
      it 'returns all users' do
        expect(parsed_body.size).to eq(2+100)
      end
    end
    context 'using filters' do
      let(:filters_q) { 'first_name=Peter' }
      it 'returns only peter' do
        expect(parsed_body.size).to eq(1)
        # Peter has id 11 from our seeds
        expect(parsed_body.map{|u| u[:uid]}).to eq(['11'])
      end
    end
  end
end