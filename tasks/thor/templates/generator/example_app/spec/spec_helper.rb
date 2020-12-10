Bundler.setup :default, :test
Bundler.require :default, :test
ENV['RACK_ENV'] = 'test'

begin
  APP=Rack::Builder.parse_file(File.expand_path('../config.ru', __dir__)).first
rescue => e
  puts "Application failed to initialize:"
  raise e
  exit 1
end

# Migrate and seed the DB (only an empty in-memory DB)
require_relative 'helpers/database_helper'
ActiveRecord::Migration.verbose = false # ?? does not seem to work like this
ActiveRecord::Tasks::DatabaseTasks.migrate
DatabaseHelper.seed!

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:suite) do
    # Praxis::Blueprint.caching_enabled = true
    DatabaseCleaner.strategy = :transaction
  end
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # config.before(:each) do
  #   Praxis::Blueprint.cache = Hash.new do |hash, key|
  #     hash[key] = Hash.new
  #   end
  # end
  
  def app
    APP
  end
end

