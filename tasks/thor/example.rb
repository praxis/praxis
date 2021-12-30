module PraxisGen
  class Example < Thor
    include Thor::Actions

    namespace 'praxis:example'

    def self.source_root
      File.dirname(__FILE__) + '/templates/generator/example_app'
    end

    argument :app_name, required: true
    desc 'example', 'Generates a new example application under an <app_name> directory to showcase some features'

    def example
      sanitized = app_name.downcase.gsub(/[^a-z0-9_\-.]/, '')
      puts "APP_NAME: #{app_name}"
      raise 'Please use only letters, numbers, underscores, dashes or periods for the app name' unless sanitized == app_name

      # Copy example files
      root_files = ['Gemfile', 'config.ru', 'Rakefile']
      root_files.each do |file|
        copy_file file, verbose: true
      end
      # Copy example directories
      root_dirs = %w[app config design db spec]
      root_dirs.each do |dir|
        directory dir, recursive: true
      end

      puts
      puts 'To run the example application:'
      puts
      puts "  cd #{app_name}"
      puts '  bundle'
      puts '  bundle exec rake db:recreate   # To create/migrate/seed the dev DB'
      puts '  bundle exec rackup             # To start the web server'
      puts
      puts 'From another terminal/app, use curl (or your favorite HTTP client) to retrieve data from the API'
      puts '  For example: '
      puts '  Get all users without filters or limit, and display only id, and first_name fields'
      puts "  curl -G -H 'X-Api-Version: 1' http://localhost:9292/users \\"
      puts '    --data-urlencode "fields=id,first_name"'
      puts
      puts '  Get the last 5 users, with last_names starting with "L" ordered by first_name (descending)'
      puts '  and display only id, first_name, last_name, and email fields'
      puts "  curl -G -H 'X-Api-Version: 1' http://localhost:9292/users \\"
      puts '    --data-urlencode "filters=last_name=L*" \\'
      puts '    --data-urlencode "pagination=by=first_name,items=5" \\'
      puts '    --data-urlencode "order=-first_name" \\'
      puts '    --data-urlencode "fields=id,first_name,last_name,email"'
      puts '  (Note: To list all routes use: bundle exec rake praxis:routes)'
      puts
      nil
    end
  end
end
