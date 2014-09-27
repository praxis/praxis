# vim: setlocal filetype=ruby:

require 'thor'
require 'pathname'
require 'yaml'

# Praxis application generator
#
# Generates all files required to run a simple praxis app.
#
class PraxisAppGenerator < Thor
  include Thor::Actions

  attr_reader  :app_name

  namespace 'praxis'
  desc "generate 'app-name'", "Generates a new PRAXIS application"

  # Generates a new praxis app in the current directory
  #
  # @param [String] name
  #
  # @return [void]
  #
  # @example
  #   # Using thor task
  #   > bundle exec thor generate my_test_app
  #
  # @example
  #   # Using 'praxis' file saved into '/usr/bin'
  #   > praxis generate my_test_app
  #
  def generate(app_name)
    # Fix weird symbols in the app name (if they are)
    @app_name = app_name.downcase.gsub(/[^a-z0-9_\/.]/, '')
    # Generate a new app
    empty_directory path('app')
    empty_directory path('design')
    empty_directory path('lib')
    empty_directory path('spec')
    generate_config_environment_rb
    generate_gemfile
    generate_rakefile
    generate_config_ru
    generate_app_definitions_hello_world
    generate_app_controllers_hello_world
    #
    puts
    puts "To run the example application:"
    puts
    puts "  # terminal 1:"
    puts "  cd #{app_name}"
    puts "  bundle"
    puts "  rackup -p 8888"
    puts
    puts "  # terminal 2:"
    puts "  curl -i http://localhost:8888/api/hello   -H 'X-Api-Version: 1.0' -X GET  # Index"
    puts "  curl -i http://localhost:8888/api/hello/2 -H 'X-Api-Version: 1.0' -X GET  # Show"
    puts "  curl -i http://localhost:8888/api/hello/2 -H 'X-Api-Version: 2.0' -X GET  # NotFound Error"
    nil
  end


private


  # Returns relative path for the new application
  #
  # @return [String]
  #
  # @example
  #  # > /praxis generate My-test_praxisApp
  #  app_dir_pathname #=> 'mytest_praxisapp'
  #
  #
  def app_dir_pathname
    @app_dir_pathname ||= Pathname.new(app_name)
  end


  # Returns path string built from the set of the given strings
  #
  # @param [String,Array] strings
  #
  # @return [String]
  #
  # @example
  #   path('a', 'b', 'c') #=> 'my_test_app/a/b/c'
  #
  def path(*strings)
    app_dir_pathname.join(*strings).to_s
  end


  # Creates './config/environment.rb' file
  #
  # @return [void]
  #
  def generate_config_environment_rb
    create_file path('config/environment.rb') do
<<-RUBY
# Main entry point - DO NOT MODIFY THIS FILE
ENV['RACK_ENV'] ||= 'development'

Bundler.require(:default, ENV['RACK_ENV'])

# Default application layout.
# NOTE: This layout need NOT be specified explicitly.
# It is provided just for illustration.
Praxis::Application.instance.layout do
  map :initializers, 'config/initializers/**/*'
  map :lib, 'lib/**/*'
  map :design, 'design/' do
    map :api, 'api.rb'
    map :media_types, '**/media_types/**/*'
    map :resources, '**/resources/**/*'
  end
  map :app, 'app/' do
    map :models, 'models/**/*'
    map :controllers, '**/controllers/**/*'
    map :responses, '**/responses/**/*'
  end
end
RUBY
    end
    nil
  end


  # Creates './Gemfile' file
  #
  # @return [void]
  #
  def generate_gemfile
    create_file path('Gemfile') do
<<-RUBY
source 'https://rubygems.org'

gem 'praxis'
gem 'rack', '~> 1.0'
gem 'rake'

group :development, :test do
  gem 'rspec'
end
RUBY
    end
    nil
  end


  # Creates './Rakefile' file
  #
  # @return [void]
  #
  def generate_rakefile
    create_file path('Rakefile') do
<<-RUBY
require 'praxis'
require 'praxis/tasks'
RUBY
    end
    nil
  end


  # Creates './config.ru' file
  #
  # @return [void]
  #
  def generate_config_ru
    create_file path('config.ru') do
<<-RUBY
#\ -p 8888

require 'bundler/setup'
require 'praxis'

application = Praxis::Application.instance
application.logger = Logger.new(STDOUT)
application.setup

run application
RUBY
    end
    nil
  end


  def generate_app_definitions_hello_world
    create_file path('design/api.rb') do
<<-RUBY
# Use this file to define your response templates and traits.
#
# For example, to define a response template:
#   response_template :custom do |media_type:|
#     status 200
#     media_type media_type
#   end
Praxis::ApiDefinition.define do
  trait :versionable do
    headers do
      key "X-Api-Version", String, values: ['1.0'], required: true
    end
  end
end
RUBY
    end

    create_file path('design/resources/hello.rb') do
<<-RUBY
module V1
  module ApiResources
    class Hello
      include Praxis::ResourceDefinition

      media_type V1::MediaTypes::Hello
      version '1.0'

      routing do
        prefix '/api/hello'
      end

      action :index do
        use :versionable

        routing do
          get ''
        end
        response :ok
      end

      action :show do
        use :versionable

        routing do
          get '/:id'
        end
        params do
          attribute :id, Integer, required: true, min: 0
        end
        response :ok
        response :not_found
      end
    end
  end
end
RUBY
    end

    create_file path('design/media_types/hello.rb') do
<<-RUBY
module V1
  module MediaTypes
    class Hello < Praxis::MediaType

      identifier 'application/json'

      attributes do
        attribute :string, String
      end

      view :default do
        attribute :string
      end
    end
  end
end
RUBY
    end
  end


  def generate_app_controllers_hello_world
      create_file path('app/controllers/hello.rb') do
<<-RUBY
module V1
  class Hello
    include Praxis::Controller

    implements V1::ApiResources::Hello

    HELLO_WORLD = [ 'Hello world!', 'Привет мир!', 'Hola mundo!', '你好世界!', 'こんにちは世界！' ]

    def index(**params)
      response.headers['Content-Type'] = 'application/json'
      response.body = HELLO_WORLD.to_json
      response
    end

    def show(id:, **other_params)
      hello = HELLO_WORLD[id]
      if hello
        response.body = { id: id, data: hello }
      else
        self.response = Praxis::Responses::NotFound.new
      end
      response.headers['Content-Type'] = 'application/json'
      response
    end
  end
end
RUBY
    end
  end

end
