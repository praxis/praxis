require 'spec_helper'

describe Praxis::Request do
  let(:env) do
    env = Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=1.0')
    env['rack.input'] = StringIO.new('something=given')
    env['HTTP_VERSION'] = 'HTTP/1.1'
    env
  end

  subject(:request) { Praxis::Request.new(env) }

  its(:verb) { should eq("GET") }
  its(:path) { should eq('/instances/1') }
  its(:raw_params) { should eq({'junk' => 'foo'}) }
  its(:version) { should eq('1.0') }

end
