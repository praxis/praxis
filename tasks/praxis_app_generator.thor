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
<<-EOF
# Main entry point - DO NOT MODIFY THIS FILE
ENV['RACK_ENV'] ||= 'development'

Bundler.require(:default, ENV['RACK_ENV'])
EOF
    end
    nil
  end


  # Creates './Gemfile' file
  #
  # @return [void]
  #
  def generate_gemfile
    create_file path('Gemfile') do
<<-EOF
source 'https://rubygems.org'

# Remove this one later when praxis does not need it
gem 'taylor', git: 'git@github.com:rightscale/taylor.git', branch: 'master'

# FIXME: replace skeletor with praxis
gem 'praxis', git: 'git@github.com:rightscale/skeletor.git', branch: 'oss'

# FIXME: remove attributor once praxis has it's own attributor dependency
gem 'attributor', git: 'git@github.com:rightscale/attributor.git', branch: 'master'

gem 'rack', '~> 1.0'
gem 'rake'

group :development, :test do
  gem 'rspec'
end
EOF
    end
    nil
  end


  # Creates './Rakefile' file
  #
  # @return [void]
  #
  def generate_rakefile
    create_file path('Rakefile') do
<<-EOF
require 'praxis'
require 'praxis/tasks'
EOF
    end
    nil
  end


  # Creates './config.ru' file
  #
  # @return [void]
  #
  def generate_config_ru
    create_file path('config.ru') do
<<-EOF
#\ -p 8888

require 'bundler/setup'
require 'praxis'

application = Praxis::Application.instance
application.logger = Logger.new(STDOUT)
application.setup

run application
EOF
    end
    nil
  end


  def generate_app_definitions_hello_world
      create_file path('app/resources/hello.rb') do
<<-EOF
module V1
  module ApiResources
    class Hello
      include Praxis::ResourceDefinition

      media_type 'application/json'
      version '1.0'

      routing do
        prefix '/api/hello'
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
      end
    end
  end
end

EOF
    end
  end


  def generate_app_controllers_hello_world
      create_file path('app/controllers/hello.rb') do
<<-EOF
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
        response.status = 404
        response.body   = { error: '404: Not found' }
      end
      response.headers['Content-Type'] = 'application/json'
      response
    end
  end
end
EOF
    end
  end

end
