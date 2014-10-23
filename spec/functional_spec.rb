require 'spec_helper'

describe 'Functional specs' , focus: true do

  def app
    Praxis::Application.instance
  end

  context 'index' do
    context 'with an incorrect response_content_type param' do
      it 'fails to validate the response' do
        get '/clouds/1/instances?response_content_type=somejunk&api_version=1.0', nil, 'HTTP_FOO' => "bar"
        response = JSON.parse(last_response.body)
        expect(response['name']).to eq('Praxis::Exceptions::Validation')
        expect(response["message"]).to match(/Bad Content-Type/)
      end

      context 'with response validation disabled' do
        let(:praxis_config) { double('praxis_config', validate_responses: false) }
        let(:config) { double('config', praxis: praxis_config) }

        before do
          expect(Praxis::Application.instance.config).to receive(:praxis).and_return(praxis_config)
        end
        
        it 'fails to validate the response' do
          expect {
            get '/clouds/1/instances?response_content_type=somejunk&api_version=1.0'
          }.to_not raise_error
        end

      end
    end

  end

  it 'works' do
    get '/clouds/1/instances/2?junk=foo&api_version=1.0'
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({"cloud_id" => 1, "id"=>2, "junk"=>"foo", 
                                                  "other_params"=>{
                                                    "some_date"=>"2012-12-21T00:00:00+00:00",
                                                    "fail_filter"=>nil}, 
                                                  "payload"=>{"something"=>nil, "optional"=>"not given"}})
    expect(last_response.headers).to eq({"Content-Type"=>"application/vnd.acme.instance", "Content-Length"=>"213"})
  end

  it 'returns early when making the before filter break' do
    get '/clouds/1/instances/2?junk=foo&api_version=1.0&fail_filter=true'
    expect(last_response.status).to eq(401)
  end

  context 'bulk_create multipart' do

    let(:instance) { Instance.example }
    let(:instance_json) { JSON.pretty_generate(instance.render(:create)) }

    let(:form) do
      form_data = MIME::Multipart::FormData.new
      entity = MIME::Text.new(instance_json)
      form_data.add entity, instance.id.to_s
      form_data
    end

    let(:content_type) { form.headers.get('Content-Type') }
    let(:body) { form.body.to_s }

    it 'works' do
      post '/clouds/1/instances?api_version=1.0', body, 'CONTENT_TYPE' => content_type

      _reponse_preamble, response = Praxis::MultipartParser.parse(last_response.headers, last_response.body)
      expect(response).to have(1).item

      response_id, instance_part = response.first
      expect(response_id).to eq(instance.id.to_s)

      instance_headers = instance_part.headers
      expect(instance_headers['Status']).to eq('201')
      expect(instance_headers['Location']).to match(%r|/clouds/.*/instances/.*|)

      response_instance = JSON.parse(instance_part.body)
      expect(response_instance["key"]).to eq(instance.id)
      expect(response_instance["value"].values).to eq(instance.render(:create).values)
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
        post '/clouds/1/instances/2/files?api_version=1.0', body, 'CONTENT_TYPE' => content_type
      end

      subject(:response) { JSON.parse(last_response.body) }

      its(['destination_path']) { should eq '/etc/defaults' }

      context 'response["file"]' do
        subject(:file) { response['file'] }

        its(['filename']) { should eq('docker') }
        its(['type']) { should eq('text/plain') }
        its(['name']) { should eq('file') }
        its(['tempfile']) { should match(/^\//) }
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
        post '/clouds/1/instances/2/files?api_version=1.0', body, 'CONTENT_TYPE' => content_type
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
        post '/clouds/1/instances/2/files?api_version=1.0', body, 'CONTENT_TYPE' => content_type
      end
      its(:keys){ should eq(['destination_path','file','options'])}
      its(['options']){ should eq({"extra_thing"=>"I am extra"})}
    end

  end


  context 'not found and API versions' do
    context 'when no version is speficied' do
      it 'it tells you which available api versions would match' do
        get '/clouds/1/instances/2?junk=foo'
        
        expect(last_response.status).to eq(404)
        expect(last_response.headers["Content-Type"]).to eq("text/plain")
        expect(last_response.body).to eq("NotFound. Your request did not specify an API version. Available versions = \"1.0\".")
      end
      it 'it just gives you a simple not found when nothing would have matched' do
        get '/foobar?junk=foo'
        
        expect(last_response.status).to eq(404)
        expect(last_response.headers["Content-Type"]).to eq("text/plain")
        expect(last_response.body).to eq("NotFound")
      end
    end

    context 'when some version is speficied, but wrong' do
      it 'it tells you which possible correcte api versions exist' do
        get '/clouds/1/instances/2?junk=foo&api_version=50.0'
        
        expect(last_response.status).to eq(404)
        expect(last_response.headers["Content-Type"]).to eq("text/plain")
        expect(last_response.body).to eq("NotFound. Your request speficied API version = \"50.0\". Available versions = \"1.0\".")
      end
    end
    
  end

  context 'volumes' do
    context 'when no authorization header is passed' do
      it 'works as expected' do
        get '/v1.0/volumes/123?junk=stuff'#, nil, 'AUTHORIZATION' => 'foobar'
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq({"id"=>123,
                                                      "other_params"=>{
                                                        "junk"=>"stuff",
                                                        "some_date"=>"2012-12-21T00:00:00+00:00"}
                                                     })
        expect(last_response.headers["Content-Type"]).to eq("application/vnd.acme.volume")
      end      
    end
    context 'when an authorization header is passed' do
      it 'returns 401 when it does not match "secret" ' do
        get '/v1.0/volumes/123?junk=stuff', nil, 'HTTP_AUTHORIZATION' => 'foobar'
        expect(last_response.status).to eq(401)
        expect(last_response.body).to match(/Authentication info is invalid/)
      end
      it 'succeeds as expected when it matches "secret" ' do
        get '/v1.0/volumes/123?junk=stuff', nil, 'HTTP_AUTHORIZATION' => 'the secret'
        expect(last_response.status).to eq(200)
      end
      
    end
  end
end
