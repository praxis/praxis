Bundler.setup :default, :test
Bundler.require :default, :test

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:suite) do
    Praxis::Blueprint.caching_enabled = true
    Praxis::Application.instance.setup
  end

  config.before(:each) do
    Praxis::Blueprint.cache = Hash.new do |hash, key|
      hash[key] = Hash.new
    end
  end

end