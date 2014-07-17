require 'spec_helper'

describe 'functional stuff' do

  def app
    Praxis::Application.instance
  end

  it 'works' do
    get '/clouds/1/instances/2?junk=foo&api_version=1.0'

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({"cloud_id" => 1, "id"=>2, "junk"=>"foo", "other_params"=>{"some_date"=>"2012-12-21T00:00:00+00:00"}, "payload"=>{"something"=>nil, "optional"=>"not given"}})
    expect(last_response.headers).to eq({"Content-Type"=>"application/json", "Content-Length"=>"188"})
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

    it 'works' do
      post '/clouds/1/instances/2/files?api_version=1.0', body, 'CONTENT_TYPE' => content_type
    end
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
      pp instance_headers

      response_instance = JSON.parse(instance_part.body)
      expect(response_instance["key"]).to eq(instance.id)
      expect(response_instance["value"].values).to eq(instance.render(:create).values)
    end
  end
end
