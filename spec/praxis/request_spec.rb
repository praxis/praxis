require 'spec_helper'

describe Praxis::Request do
  let(:rack_input) { StringIO.new('something=given') }
  let(:env) do
    env = Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=1.0')
    env['rack.input'] = rack_input
    env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded'
    env['HTTP_VERSION'] = 'HTTP/1.1'
    env
  end

  let(:action) { Instances.actions[:show] }

  let(:context) do
    {
      params: [Attributor::AttributeResolver::ROOT_PREFIX, "params".freeze],
      headers: [Attributor::AttributeResolver::ROOT_PREFIX, "headers".freeze],
      payload: [Attributor::AttributeResolver::ROOT_PREFIX, "payload".freeze]
    }.freeze
  end

  subject(:request) do
    request = Praxis::Request.new(env)
    request.action = action
    request
  end

  its(:verb) { should eq("GET") }
  its(:path) { should eq('/instances/1') }
  its(:raw_params) { should eq({'junk' => 'foo'}) }
  its(:version) { should eq('1.0') }

  context 'with a multipart requset' do
    let(:form) do
      form_data = MIME::Multipart::FormData.new

      entity = MIME::Text.new('some_value')
      form_data.add entity, 'something'

      form_data
    end

    let(:rack_input) { 
      StringIO.new(form.body.to_s) 
    }

    let(:env) do
      env = Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=1.0')
      env['rack.input'] = rack_input
      env['HTTP_VERSION'] = 'HTTP/1.1'
      env['CONTENT_TYPE'] = form.headers.get('Content-Type')
      env
    end

    #its(:multipart?) { should be(true) }

    it 'works' do
      #p request #.body
      #p request #.parts
    end


  end

  context "performs request validation" do
    before(:each) do
      request.load_headers(context[:headers])
      request.load_params(context[:params])
    end

    context '#validate_headers' do
      it 'should validate headers' do
        expect(request.headers).to receive(:validate).and_return([])
        request.validate_headers(context[:headers])
      end

      it 'should raise an error if headers validation failed' do
        allow(request.headers).to receive(:validate).and_return(['some_error'])
        expect(request.validate_headers(context[:headers])).to eq(['some_error'])
      end
    end

    context '#validate_params' do
      it 'should validate params' do
        expect(request.params).to receive(:validate).and_return([])
        request.validate_params(context[:params])
      end

      it 'should raise an error if params validation failed' do
        allow(request.params).to receive(:validate).and_return(['some_error'])
        expect(request.validate_params(context[:params])).to eq(['some_error'])
      end
    end

    context '#validate_payload' do
      before { request.load_payload('') }
      it 'should validate payload' do
        expect(request.payload).to receive(:validate).and_return([])
        request.validate_payload(context[:payload])
      end

      it 'should raise an error if payload validation failed' do
        expect(request.payload).to receive(:validate).and_return(['some_error'])
        expect(request.validate_payload(context[:payload])).to eq(['some_error'])
      end
    end
  end
end
