$:.unshift File.expand_path(__dir__)
$:.unshift File.expand_path('../lib',__dir__)
$:.unshift File.expand_path('support',__dir__)

require 'bundler'
Bundler.setup :default, :test

require 'simplecov'
SimpleCov.start 'praxis'

require 'praxis'

require 'rack/test'

require 'rspec/its'
require 'rspec/collection_matchers'

require 'pry'

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
 require file
end


RSpec.configure do |config|
  config.include Rack::Test::Methods
  
  config.before(:suite) do
    Taylor::Blueprint.caching_enabled = false
    Praxis::Application.instance.setup
  end

end
