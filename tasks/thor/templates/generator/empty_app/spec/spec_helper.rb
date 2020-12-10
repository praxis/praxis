Bundler.setup :default, :test
Bundler.require :default, :test

RSpec.configure do |config|
  config.include Rack::Test::Methods

  # config.before(:suite) do
  #   Praxis::Blueprint.caching_enabled = true
  # end

  # config.before(:each) do
  #   Praxis::Blueprint.cache = Hash.new do |hash, key|
  #     hash[key] = Hash.new
  #   end
  # end
end

def app
  Rack::Builder.parse_file(File.expand_path('../config.ru', __dir__)).first
rescue => e
  puts "Application failed to initialize: #{e}"
  exit 1
end