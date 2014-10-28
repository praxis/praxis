require 'spec_helper'

describe Praxis::Request do
  let(:rack_input) { StringIO.new('something=given') }
  let(:env) do
    env = Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=1.0')
    env['rack.input'] = rack_input
    env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded'
    env['HTTP_VERSION'] = 'HTTP/1.1'
    env['HTTP_AUTHORIZATION'] = 'Secret'
    env
  end

  let(:action) { Instances.definition.actions[:show] }

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
  
  context 'path versioning' do
    its('class.path_version_prefix'){ should eq("/v") }
    its(:path_version_matcher){ should be_kind_of(Regexp) }
    it 'uses a "/v*" default matcher with a "version" named capture' do
      match = subject.path_version_matcher.match("/v5.5/something")
      expect(match).to_not be(nil)
      expect(match['version']).to eq("5.5")
    end
  end
  
  context 'loading api version' do
    let(:request) { Praxis::Request.new(env) }
    subject(:version){ request.version( version_options ) }
    context 'using X-Api-Header' do
      let(:env){ {'HTTP_X_API_VERSION' => "5.0", "PATH_INFO" => "/something"} }
      let(:version_options){ {using: :header} }
      it { should eq('5.0') }
    end
    context 'using query param' do
      let(:env) { Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=5.0') }
      let(:version_options){ {using: :params} }
      it { should eq('5.0') }
    end
    context 'using path (with the default pattern matcher)' do
      let(:env){ Rack::MockRequest.env_for('/v5.0/instances/1?junk=foo') }
      let(:version_options){ {using: :path} }
      it { should eq('5.0') }  
    end
    
    context 'using a method that it is not allowed in the definition' do
      context 'allowing query param but passing it through a header' do
        let(:env){ {'HTTP_X_API_VERSION' => "5.0", "PATH_INFO" => "/something"} }
        let(:version_options){ {using: :params} }
        it { should eq('n/a') }
      end
      context 'allowing header but passing it through param' do
        let(:env) { Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=5.0') }
        let(:version_options){ {using: :header} }
        it { should eq('n/a') }
      end
    end
    
    context 'using defaults' do
      subject(:version){ request.version }
      context 'would succeed if passed through the header' do
        let(:env){ {'HTTP_X_API_VERSION' => "5.0", "PATH_INFO" => "/something"} }
        it { should eq('5.0') }
      end
      context 'would succeed if passed through params' do
        let(:env) { Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=5.0') }
        it { should eq('5.0') }
      end
    end
  end

  context 'with a multipart request' do
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

  context '#load_headers' do

    it 'is done preserving the original case' do
      request.load_headers(context[:headers])
      expect(request.headers).to match({"Authorization" => "Secret"})
    end

    it 'performs it using the memoized rack keys from the action (Hacky but...performance is important)' do
      expect(action).to receive(:precomputed_header_keys_for_rack).and_call_original
      request.load_headers(context[:headers])
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
