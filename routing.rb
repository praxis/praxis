require 'pp'
require 'json'

require 'bundler/setup'

$:.unshift File.expand_path('lib', __dir__)

require 'praxis'


application = Praxis::Application.instance

application.setup



env = Rack::MockRequest.env_for('/instances/1?junk=foo&api_version=1.0')
env['rack.input'] = StringIO.new('something=given')
env['HTTP_VERSION'] = 'HTTP/1.1'

status, headers, body = application.call(env)

puts "status: #{status}"
puts "headers: #{headers}"
puts "----------"
pp JSON.parse(body.first)


# class MockRequest
#   def payload
#     {}
#   end
#   def params_hash
#     {}
#   end
# end

# request = MockRequest.new

# response = Instances.new(request).show(id:1, junk:'stuff', some_date:DateTime.now)

# p response.status
# p response.body






