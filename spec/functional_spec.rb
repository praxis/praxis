require 'spec_helper'

Praxis::Application.instance.setup


describe 'functional stuff' do

  def app 
    Praxis::Application.instance
  end

  it 'works' do
    get '/instances/1?junk=foo&api_version=1.0'
    expect(last_response.status).to eq(200)

    expect(JSON.parse(last_response.body)).to eq({"id"=>1, "junk"=>"foo", "other_params"=>{"some_date"=>"2012-12-21T00:00:00+00:00"}, "payload"=>{"something"=>nil, "optional"=>"not given"}})
    expect(last_response.headers).to eq({"Content-Type"=>"application/json", "Content-Length"=>"171"})

  end

end