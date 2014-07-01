$:.unshift File.expand_path(__dir__)
$:.unshift File.expand_path('../lib',__dir__)
$:.unshift File.expand_path('support',__dir__)

require 'bundler'
Bundler.setup :default, :test

require 'praxis'

require 'rack/test'

require 'rspec/its'


Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
 require file
end


RSpec.configure do |config|
  config.include Rack::Test::Methods
  
  config.before(:suite) do
    Praxis::Application.instance.setup
  end

end
