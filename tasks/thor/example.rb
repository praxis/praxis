
module PraxisGen
  class Example < Thor
    include Thor::Actions

    namespace "praxis:example"

    def self.source_root
      File.dirname(__FILE__) + "/templates/generator/example_app"
    end

    argument :app_name, required: true
    desc "example", "Generates a new example application under an <app_name> directory to showcase some features"

    def example
      sanitized = app_name.downcase.gsub(/[^a-z0-9_\-.]/, '')
      puts "APP_NAME: #{app_name}"
      raise "Please use only letters, numbers, underscores, dashes or periods for the app name" unless sanitized == app_name

      # Copy example files
      root_files = ['Gemfile','config.ru','Rakefile']
      root_files.each do |file|
        copy_file file, verbose: true
      end
      # Copy example directories
      root_dirs = ['app','config','design','db','spec']
      root_dirs.each do |dir|
        directory dir, recursive: true
      end

      puts
      puts "To run the example application:"
      puts
      puts "  cd #{app_name}"
      puts "  bundle"
      puts "  bundle exec rake db:create db:migrate db:seed  # To create/migrate/seed the dev DB"
      puts "  bundle exec rackup                             # To start the web server"
      puts  
      puts "From another terminal/app, use curl (or your favorite HTTP client) to retrieve data from the API"
      puts "  For example: "
      puts "  Get all users without filters or limit, and display only uid, and last_name fields"
      puts "  curl -H 'X-Api-Version: 1' http://localhost:9292/users?fields=uid,last_name"
      puts
      puts "  Get the last 5 users, ordered by last_name (descending),  and display only uid, and last_name fields"
      puts "  curl -H 'X-Api-Version: 1' 'http://localhost:9292/users?fields=uid,last_name&order=-last_name&pagination=by%3Dlast_name,items%3D5' "
      puts "  (Note: To list all routes use: bundle exec rake praxis:routes)"
      puts
      nil
    end
  end
end
