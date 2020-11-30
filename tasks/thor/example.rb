
module PraxisGen
      class Example < Thor
        include Thor::Actions

        namespace "praxis:example"

        argument :app_name, required: true
        desc "new", "Generates a new 'hello world' example application under an <app_name> directory"

        def new
          puts "GENERATION COMMENCED!! (for #{app_name})"
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
          puts "  bundle exec rackup"
          puts
          puts "  # terminal 2:"
          puts "  # Index: list the hello words (especifying api version through the query string) "
          puts "  curl -i 'http://localhost:8888/api/hello?api_version=1.0' -H 'Authorization: Bearer XYZ' "
          puts ""
          puts "  # Show: list one of the hello words (especifying api version through a header) "
          puts "  curl -i 'http://localhost:8888/api/hello/1' -H 'X-Api-Version: 1.0' -H 'Authorization: Bearer XYZ'"
          puts ""
          puts "  # NotFound: Hello word will not be found under API 2.0"
          puts "  curl -i 'http://localhost:8888/api/hello/1' -H 'X-Api-Version: 2.0' -H 'Authorization: Bearer XYZ'"
          puts "  #Note: The Authorization header is made required in the application to emulate OAuth2 (but not used)"
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
#\\ -p 8888

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
  # Trait that when included will require a Bearer authorization header to be passed in.
  trait :authorized do
    headers do
      key "Authorization", String, regexp: /^.*Bearer\s/, required: true
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
      include Praxis::EndpointDefinition

      media_type V1::MediaTypes::Hello
      version '1.0'

      prefix '/api/hello'

      # Will apply to all actions of this resource
      trait :authorized

      action_defaults do
        response :ok
      end

      action :index do

        routing do
          get ''
        end
      end

      action :show do

        routing do
          get '/:id'
        end
        params do
          attribute :id, Integer, required: true, min: 0
        end
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
        self.response = Praxis::Responses::NotFound.new(body: "Hello word with index \#{id} not found in our DB")
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
end