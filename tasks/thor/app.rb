# frozen_string_literal: true

module PraxisGen
  class App < Thor
    include Thor::Actions

    namespace 'praxis:app'
    def self.source_root
      "#{File.dirname(__FILE__)}/templates/generator/empty_app"
    end

    argument :app_name, required: true
    desc 'new', 'Generates a blank new app under <app_name> (with a full skeleton ready to start coding)'

    # Generator for a blank new app (with a full skeleton ready to get you going)
    def new
      puts "Creating new blank Praxis app under #{app_name}"
      # Copy example files
      ['config.ru', 'Gemfile', 'Rakefile', 'README.md'].each do |file|
        copy_file file, verbose: true
      end
      # Copy example directories
      root_dirs = %w[config app design spec docs]
      root_dirs.each do |dir|
        directory dir, recursive: true
      end
    end
  end
end
