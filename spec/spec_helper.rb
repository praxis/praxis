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

Dir["#{File.dirname(__FILE__)}/../lib/praxis/plugins/*.rb"].each do |file|
  require file
end

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
  require file
end


RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:suite) do
    Praxis::Blueprint.caching_enabled = true
    Praxis::Application.instance.setup(root:'spec/spec_app')

    # create the table
    setup_database!
  end

  config.before(:each) do
    Praxis::Blueprint.cache = Hash.new do |hash, key|
      hash[key] = Hash.new
    end
  end

  config.before(:all) do
    # disable debug logging (to avoid PraxisMapper plugin logging)
    Praxis::Application.instance.logger.level = 1 # info
  end
end

# create the test db schema
def setup_database!
  mapper = Praxis::Application.instance.plugins[:praxis_mapper]
  Sequel.connect(mapper.config.repositories["default"]['connection_settings'].dump) do |db|
    db.create_table! :people do
      primary_key :id
      string :name
    end
  end
end
