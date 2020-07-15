require 'coveralls'
Coveralls.wear!

$:.unshift File.expand_path(__dir__)
$:.unshift File.expand_path('../lib',__dir__)
$:.unshift File.expand_path('support',__dir__)

require 'bundler'
Bundler.setup :default, :test
require 'simplecov'
SimpleCov.start 'praxis'

require 'pry'

require 'praxis'

require 'rack/test'

require 'rspec/its'
require 'rspec/collection_matchers'

Dir["#{File.dirname(__FILE__)}/../lib/praxis/plugins/*.rb"].each do |file|
  require file
end


Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
  require file
end

def suppress_output
  original_stdout, original_stderr = $stdout.clone, $stderr.clone
  $stderr.reopen File.new('/dev/null', 'w')
  $stdout.reopen File.new('/dev/null', 'w')
  yield
ensure
  $stdout.reopen original_stdout
  $stderr.reopen original_stderr
end

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:suite) do
    Praxis::Mapper::Resource.finalize!
    Praxis::Blueprint.caching_enabled = true
    Praxis::Application.instance.setup(root:'spec/spec_app')
  end

  config.before(:each) do
    Praxis::Blueprint.cache = Hash.new do |hash, key|
      hash[key] = Hash.new
    end
  end

  config.before(:all) do
    # disable logging below warn level
    Praxis::Application.instance.logger.level = 2 # warn
  end
end

