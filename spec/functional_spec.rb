require 'spec_helper'

describe 'Functional specs' do

  def app
    Praxis::Application.instance
  end

  let(:session) { double("session", valid?: true)}

  context 'index' do

    context 'with a valid request' do
      it 'is successful' do
        get '/api/clouds/1/instances?api_version=1.0', nil, 'global_session' => session
        expect(last_response.headers['Content-Type']).to(
        eq("application/vnd.acme.instance;type=collection"))
      end
    end

    context 'with a path param that can not load' do
      it 'returns a useful error' do
        get '/api/clouds/invalid/instances?api_version=1.0', nil, 'global_session' => session

        expect(last_response.status).to eq 400

        response = JSON.parse(last_response.body)
        expect(response['name']).to eq 'ValidationError'
        expect(response['summary']).to eq 'Error loading params.'
        expect(response['errors']).to match_array([/Error loading attribute \$\.params\.cloud_id/])
        expect(response['cause']['name']).to eq 'ArgumentError'
      end
    end

    context 'with a header that can not load' do
      it 'returns a useful error' do
        get '/api/clouds/1/instances?api_version=1.0', nil, 'global_session' => session, 'HTTP_ACCOUNT_ID' => 'invalid'

        expect(last_response.status).to eq 400

        response = JSON.parse(last_response.body)

        expect(response['name']).to eq 'ValidationError'
        expect(response['summary']).to eq 'Error loading headers.'
        expect(response['errors']).to match_array([/Error loading attribute .*Account-Id"/])
        expect(response['cause']['name']).to eq 'ArgumentError'
      end
    end

    context 'with a param that is invalid' do
      it 'returns a useful error' do
        get '/api/clouds/-1/instances?api_version=1.0', nil, 'global_session' => session

        expect(last_response.status).to eq 400

        response = JSON.parse(last_response.body)

        expect(response['name']).to eq 'ValidationError'
        expect(response['summary']).to eq 'Error validating request data.'
        expect(response['errors']).to match_array([/.*cloud_id.*is smaller than the allowed min/])
      end

    end

    context 'with a header that is invalid' do
      it 'returns a useful error' do
        get '/api/clouds/1/instances?api_version=1.0', nil, 'global_session' => session, 'HTTP_ACCOUNT_ID' => '-1'

        expect(last_response.status).to eq 400

        response = JSON.parse(last_response.body)

        expect(response['name']).to eq 'ValidationError'
        expect(response['summary']).to eq 'Error validating request data.'
        expect(response['errors']).to match_array([/.*headers.*Account-Id.*is smaller than the allowed min/])
      end
    end

    context 'with an incorrect response_content_type param' do
      around do |example|
        logger = app.logger
        app.logger = Logger.new(StringIO.new)

        example.call

        app.logger = logger
      end

      it 'fails to validate the response' do
        get '/api/clouds/1/instances?response_content_type=somejunk&api_version=1.0', nil, 'HTTP_FOO' => "bar", 'global_session' => session
        expect(last_response.status).to eq(400)
        response = JSON.parse(last_response.body)

        expect(response['name']).to eq('ValidationError')
        expect(response['summary']).to eq("Error validating response")
        expect(response['errors'].first).to match(/Bad Content-Type/)
      end

      context 'with response validation disabled' do
        let(:praxis_config) { double('praxis_config', validate_responses: false) }
        let(:config) { double('config', praxis: praxis_config) }

        before do
          expect(Praxis::Application.instance.config).to receive(:praxis).and_return(praxis_config)
        end

        it 'fails to validate the response' do
          expect {
            get '/api/clouds/1/instances?response_content_type=somejunk&api_version=1.0',nil,  'global_session' => session
          }.to_not raise_error
        end

      end
    end

  end

  it 'works' do
    the_body = StringIO.new("{}") # This is a funny, GET request expecting a body
    get '/api/clouds/1/instances/2?junk=foo&api_version=1.0', nil,'rack.input' => the_body,'CONTENT_TYPE' => "application/json", 'global_session' => session
    expect(last_response.status).to eq(200)
    expected = {
      "cloud_id" => 1,
      "id"=>2,
      "junk"=>"foo",
      "other_params"=>{
        "some_date"=>"2012-12-21T00:00:00+00:00",
        "fail_filter"=>false
      },
      "payload"=>{
      "optional"=>"not given"}
    }

    expect(JSON.parse(last_response.body)).to eq(expected)

    headers = last_response.headers
    expect(headers['Content-Type']).to eq('application/json')
    expect(headers['Spec-Middleware']).to eq('used')
  end

  it 'returns early when making the before filter break' do
    get '/api/clouds/1/instances/2?junk=foo&api_version=1.0&fail_filter=true', nil, 'global_session' => session
    expect(last_response.status).to eq(401)
  end

  context 'bulk_create multipart' do

    let(:instance) { Instance.example }
    let(:instance_json) { JSON.pretty_generate(instance.render(view: :create)) }

    let(:form) do
      form_data = MIME::Multipart::FormData.new
      entity = MIME::Text.new(instance_json)
      form_data.add entity, instance.id.to_s
      form_data
    end

    let(:content_type) { form.headers.get('Content-Type') }
    let(:body) { form.body.to_s }

    it 'works' do
      post '/api/clouds/1/instances?api_version=1.0', body, 'CONTENT_TYPE' => content_type, 'global_session' => session

      _reponse_preamble, response = Praxis::MultipartParser.parse(last_response.headers, last_response.body)
      expect(response).to have(1).item

      instance_part = response.first
      response_id = instance_part.name
      expect(response_id).to eq(instance.id.to_s)

      instance_headers = instance_part.headers
      expect(instance_headers['Status']).to eq('201')
      expect(instance_headers['Location']).to match(%r|/clouds/.*/instances/.*|)

      response_instance = JSON.parse(instance_part.body)
      expect(response_instance["key"]).to eq(instance.id)
      expect(response_instance["value"].values).to eq(instance.render(view: :create).values)
    end
  end


  context 'attach_file' do
    let(:form) do
      form_data = MIME::Multipart::FormData.new

      destination_path = MIME::Text.new('/etc/defaults')
      form_data.add destination_path, 'destination_path'

      text = MIME::Text.new('DOCKER_HOST=tcp://127.0.0.1:2375')
      form_data.add text, 'file', 'docker'

      form_data
    end

    let(:content_type) { form.headers.get('Content-Type') }
    let(:body) { form.body.to_s }

    context 'with a valid payload' do
      before do
        post '/api/clouds/1/instances/2/files?api_version=1.0', body, 'CONTENT_TYPE' => content_type, 'global_session' => session
      end

      subject(:response) { JSON.parse(last_response.body) }

      its(['destination_path']) { should eq '/etc/defaults' }

      context 'response["file"]' do
        subject(:file) { response['file'] }

        its(['filename']) { should eq('docker') }
        its(['type']) { should eq('text/plain') }
        its(['name']) { should eq('file') }
        its(['tempfile']) { should eq('DOCKER_HOST=tcp://127.0.0.1:2375') }
      end
    end

    context 'with a missing value in form' do
      let(:form) do
        form_data = MIME::Multipart::FormData.new

        text = MIME::Text.new('DOCKER_HOST=tcp://127.0.0.1:2375')
        form_data.add text, 'file', 'docker'

        form_data
      end

      let(:body) { form.body.to_s }

      it 'returns an error' do
        post '/api/clouds/1/instances/2/files?api_version=1.0', body, 'CONTENT_TYPE' => content_type, 'global_session' => session
        response = JSON.parse(last_response.body)

        expect(response['name']).to eq('ValidationError')
        expect(response['errors']).to eq(["Attribute $.payload.key(\"destination_path\") is required"])
      end

    end

    context 'with an extra key in the form' do
      let(:form) do
        form_data = MIME::Multipart::FormData.new

        destination_path = MIME::Text.new('/etc/defaults')
        form_data.add destination_path, 'destination_path'

        text = MIME::Text.new('DOCKER_HOST=tcp://127.0.0.1:2375')
        form_data.add text, 'file', 'docker'

        # TEST EXTRA KEYS USING THE MULTIPART FORM
        other = MIME::Text.new('I am extra')
        form_data.add other, 'extra_thing'

        form_data
      end

      let(:body) { form.body.to_s }
      subject(:response) { JSON.parse(last_response.body) }

      before do
        post '/api/clouds/1/instances/2/files?api_version=1.0', body, 'CONTENT_TYPE' => content_type, 'global_session' => session
      end
      its(:keys){ should eq(['destination_path','file','options'])}
      its(['options']){ should eq({"extra_thing"=>"I am extra"})}
    end

  end


  context 'not found and API versions' do
    context 'when no version is specified' do
      it 'it tells you which available api versions would match' do
        get '/api/clouds/1/instances/2?junk=foo',nil, 'global_session' => session

        expect(last_response.status).to eq(404)
        expect(last_response.headers["Content-Type"]).to eq("text/plain")
        expect(last_response.body).to eq("NotFound. Your request did not specify an API version. Available versions = \"1.0\".")
      end
      it 'it just gives you a simple not found when nothing would have matched' do
        get '/foobar?junk=foo', nil, 'global_session' => session

        expect(last_response.status).to eq(404)
        expect(last_response.headers["Content-Type"]).to eq("text/plain")
        expect(last_response.body).to eq("NotFound")
      end
    end

    context 'when some version is specified, but wrong' do
      it 'it tells you which possible correcte api versions exist' do
        get '/api/clouds/1/instances/2?junk=foo&api_version=50.0', nil, 'global_session' => session

        expect(last_response.status).to eq(404)
        expect(last_response.headers["Content-Type"]).to eq("text/plain")
        expect(last_response.body).to eq("NotFound. Your request specified API version = \"50.0\". Available versions = \"1.0\".")
      end
    end

  end

  context 'volumes' do
    before do
      header 'X-Api-Version', '1.0'
    end

    context 'when no authorization header is passed' do
      it 'works as expected' do
        get '/api/clouds/1/volumes/123?junk=stuff', nil, 'global_session' => session
        expect(last_response.status).to eq(200)
        expect(Volume.load(last_response.body).validate).to be_empty
        expect(last_response.headers["Content-Type"]).to eq("application/vnd.acme.volume")
      end
    end
    context 'when an authorization header is passed' do
      it 'returns 401 when it does not match "secret" ' do
        get '/api/clouds/1/volumes/123?junk=stuff', nil, 'HTTP_AUTHORIZATION' => 'foobar', 'global_session' => session
        expect(last_response.status).to eq(401)
        expect(last_response.body).to match(/Authentication info is invalid/)
      end
      it 'succeeds as expected when it matches "secret" ' do
        get '/api/clouds/1/volumes/123?junk=stuff', nil, 'HTTP_AUTHORIZATION' => 'the secret', 'global_session' => session
        expect(last_response.status).to eq(200)
      end

    end

    context 'index action with no args defined' do
      it 'dispatches successfully' do
        get '/api/clouds/1/volumes', nil, 'HTTP_AUTHORIZATION' => 'the secret', 'global_session' => session
        expect(last_response.status).to eq(200)
      end
    end
  end

  context 'wildcard verb routing' do
    let(:content_type){ 'application/json' }
    it 'can terminate instances with POST' do
      post '/api/clouds/23/instances/1/terminate?api_version=1.0', nil, 'CONTENT_TYPE' => content_type, 'global_session' => session
      puts last_response.body
      #binding.pry
      expect(last_response.status).to eq(200)
    end
    it 'can terminate instances with DELETE' do
      post '/api/clouds/23/instances/1/terminate?api_version=1.0', nil, 'CONTENT_TYPE' => content_type, 'global_session' => session
      expect(last_response.status).to eq(200)
    end

  end

  context 'route options' do
    it 'reach the endpoint that does not match the except clause' do
      get '/api/clouds/23/otherinstances/_action/test?api_version=1.0', nil, 'global_session' => session
      expect(last_response.status).to eq(200)
    end
    it 'does NOT reach the endpoint that matches the except clause' do
      get '/api/clouds/23/otherinstances/_action/exceptional?api_version=1.0', nil, 'global_session' => session
      expect(last_response.status).to eq(404)
    end
  end

  context 'auth_plugin' do
    it 'can terminate' do
      post '/api/clouds/23/instances/1/terminate?api_version=1.0', nil, 'global_session' => session
      expect(last_response.status).to eq(200)
    end

    it 'can not stop' do
      post '/api/clouds/23/instances/1/stop?api_version=1.0', '', 'global_session' => session
      expect(last_response.status).to eq(403)
    end
  end

  context 'with mismatch between Content-Type and payload' do
    let(:body) { 'some-text' }
    let(:content_type) { 'application/json' }

    before do
      post '/api/clouds/1/instances/2/terminate?api_version=1.0', body, 'CONTENT_TYPE' => content_type, 'global_session' => session
    end

    it 'returns a useful error message' do
      body = JSON.parse(last_response.body)
      expect(body['name']).to eq('ValidationError')
      expect(body['summary']).to match("Error loading payload. Used Content-Type: 'application/json'")
      expect(body['errors']).to_not be_empty
    end
  end

  context 'update' do

    let(:body) { JSON.pretty_generate(request_payload) }
    let(:content_type) { 'application/json' }

    before do
      patch '/api/clouds/1/instances/3?api_version=1.0', body, 'CONTENT_TYPE' => content_type, 'global_session' => session
    end

    subject(:response_body) { JSON.parse(last_response.body) }

    context 'with an empty payload' do
      let(:request_payload) { {} }
      it { should be_empty }
      it { should_not have_key('name') }
      it { should_not have_key('root_volume') }
    end

    context 'with a provided name' do
      let(:request_payload) { {name: 'MyInstance'} }
      its(['name']) { should eq('MyInstance') }
      it { should_not have_key('root_volume') }
    end

    context 'with an explicitly-nil root_volme' do
      let(:request_payload) { {name: 'MyInstance', root_volume: nil} }
      its(['name']) { should eq('MyInstance') }
      its(['root_volume']) { should be(nil) }
    end

    context 'with an invalid name' do
      let(:request_payload) { {name: 'Invalid Name'} }

      its(['name']) { should eq 'ValidationError' }
      its(['summary']) { should eq 'Error validating response' }
      its(['errors']) { should match_array [/\$\.name value \(Invalid Name\) does not match regexp/] }

      it 'returns a validation error' do
        expect(last_response.status).to eq(400)
      end
    end

  end

end
