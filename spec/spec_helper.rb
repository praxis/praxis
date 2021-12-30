# frozen_string_literal: true

require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path(__dir__)
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('support', __dir__)

require 'bundler'
Bundler.setup :default, :test

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

require 'simplecov'
SimpleCov.start 'praxis'

require 'pry'
require 'pry-byebug'

require 'praxis'

require 'rack/test'

require 'rspec/its'
require 'rspec/collection_matchers'

Dir["#{File.dirname(__FILE__)}/../lib/praxis/plugins/*.rb"].sort.each do |file|
  require file
end

Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each do |file|
  require file
end

def suppress_output
  original_stdout = $stdout.clone
  original_stderr = $stderr.clone
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
    Praxis::Application.instance.setup(root: 'spec/spec_app')
  end

  config.before(:each) do
    Praxis::Blueprint.cache = Hash.new do |hash, key|
      hash[key] = {}
    end
  end

  config.before(:all) do
    # disable logging below warn level
    Praxis::Application.instance.logger.level = 2 # warn
  end
end
