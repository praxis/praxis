require 'spec_helper'

describe Praxis::Request do
  Given(:env) do
    env = Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=1.0')
    env['rack.input'] = StringIO.new('something=given')
    env['HTTP_VERSION'] = 'HTTP/1.1'
    env
  end

  Given(:request) { Praxis::Request.new(env) }

  
  Then { request.verb == "GET" }
  And { request.path == '/instances/1' }
  And { request.raw_params == {'junk' => 'foo'} }
  And { request.version == '1.0' }
  
end
