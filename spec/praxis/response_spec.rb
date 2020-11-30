require 'spec_helper'


describe Praxis::Response do
  let(:spec_status)     { 200 }
  let(:spec_location)   { /resources/ }
  let(:spec_headers)    { { 'X-Header' => 'Foobar' } }
  let(:spec_mime_type)  { "application/vnd.resource" }

  let(:application_vnd_resource_media_type) do
    Class.new(Praxis::MediaType) do
      identifier 'application/vnd.resource'
    end
  end

  let(:spec_media_type) { application_vnd_resource_media_type }

  let(:response_spec) do
    instance_double(
      Praxis::ResponseDefinition,
      :status     => spec_status,
      :location   => spec_location,
      :headers    => spec_headers,
      :media_type => spec_media_type,
      :name       => :ok
    )
  end

  let(:action) do
    instance_double(
      Praxis::ActionDefinition,
      :endpoint_definition => config_class
    )
  end

  let(:response_status)  { 200 }
  let(:response_headers) {
    { 'Content-Type' => 'application/vnd.resource+json;type=collection',
      'X-Header'     => 'Foobar',
      'Location'     => '/api/resources/123' }
  }

  let(:config_media_type) { nil }
  let(:config_class) do
    instance_double(
      Praxis::ResponseDefinition,
      :media_type => config_media_type
    )
  end

  subject(:response) { Praxis::Responses::Ok.new(status: response_status, headers: response_headers) }

  describe '#validate' do
    before do
      allow(action).to receive(:responses).and_return({response_spec.name => response_spec })
    end
    context 'response spec is not defined' do
      before :each do
        allow(response.class).to receive(:response_name).and_return(:nonexisting_spec)
      end

      it 'should raise an error' do
        expect {
          response.validate(action)
        }.to raise_error(Praxis::Exceptions::Validation, /response definition with that name can be found/)
      end
    end

    context 'with an existing response spec in the action' do

      it 'should use the spec to validate the response' do
        expect(response_spec).to receive(:validate).and_return(nil)

        response.validate(action)
      end
    end


  end

  describe '#encode!' do
    let(:response_body_structured_data) { [{"moo" => "bah"}] }
    let(:response_body_entity) { '[{"moo": "bah"}]' }

    context 'given a String body' do
      before { response.body = response_body_entity }

      it 'leaves well enough alone' do
        response.encode!
        expect(response.body).to eq(response_body_entity)
      end
    end

    context 'given a structured body' do
      before { response.body = response_body_structured_data }

      it 'encodes using a suitable handler' do
        response.encode!
        expect(JSON.load(response.body)).to eq(response_body_structured_data)
      end
    end

    context 'when no Content-Type is defined' do
      before { response.body = response_body_structured_data }

      let(:response_headers) {
        { 'X-Header'     => 'Foobar',
          'Location'     => '/api/resources/123' }
      }
      it 'still defaults to the default handler' do
        response.encode!
        expect(JSON.load(response.body)).to eq(response_body_structured_data)
      end
    end


  end

  context 'multipart responses' do
    let(:part) { Praxis::MultipartPart.new('not so ok', {'Status' => 400, "Location" => "somewhere"}) }

    context '#add_part' do

      context 'without a name' do
        before do
          response.add_part(part)
        end

        its(:parts) { should have(1).item }

        it 'sets the Content-Type header' do
          expect(response.headers['Content-Type']).to match(/^multipart.*boundary=/i)
        end

        it 'adds the part' do
          expect(response.parts.values.first).to be(part)
        end
      end

      context 'with a name' do
        let(:part_name) { 'a-part' }
        before do
          response.add_part(part_name, part)
        end

        it 'adds the part' do
          expect(response.parts[part_name]).to be(part)
        end
      end

    end

    context '#finish for a multipart response' do

      before do
        response.add_part(part)
        response.body = 'a preamble'
        response.status = 500
      end

      let!(:finished_response) { response.finish }

      it 'returns status, headers, body' do
        expect(finished_response).to eq([response.status, response.headers, response.body])
      end

      its(:status) { should eq(500) }

      it 'sets a preamble in the body' do
        expect(response.body[0]).to eq('a preamble')
        expect(response.body[1]).to eq("\r\n")
      end

      it 'sets the headers' do
        expect(response.headers['Content-Type']).to match(/multipart\/form-data/)
        expect(response.headers['Location']).to eq('/api/resources/123')
      end

      it 'encodes the body properly' do
        parser = Praxis::MultipartParser.new(response.headers, response.body)
        preamble, parts = parser.parse

        expect(preamble).to eq("a preamble")
        expect(parts).to have(1).item

        part_response = parts.first
        expect(part_response.headers['Status']).to eq(part.headers['Status'].to_s)
        expect(part_response.headers['Location']).to eq(part.headers['Location'])
        expect(part_response.body).to eq('not so ok')
      end
    end

  end



end
