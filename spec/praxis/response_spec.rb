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
      :resource_definition => config_class
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

  subject(:response) { Praxis::Responses::Default.new(status: response_status, headers: response_headers) }

  # before :each do
  #   allow(response.class).to receive(:response_name).and_return(:spec)
  #   #allow(response).to       receive(:headers).and_return(response_headers)
  #   #allow(response).to       receive(:status).and_return(response_status)
  # end
  
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
        }.to raise_error(ArgumentError, /response definition with that name can be found/)
      end
    end
    
    context 'with an existing response spec in the action' do
  
      it 'should use the spec to validate the response' do
        expect(response_spec).to receive(:validate).and_return(nil)

        response.validate(action)
      end
    end

    
  end


end
