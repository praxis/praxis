module PraxisGen
  class App < Thor
    include Thor::Actions
  
    namespace "praxis:app"
    def self.source_root
      File.dirname(__FILE__) + "/templates/generator/empty_app"
    end
  
    argument :app_name, required: true
    desc "new", "Generates a blank new app under <app_name> (with a full skeleton ready to start coding)"
  
    # Generator for a blank new app (with a full skeleton ready to get you going)
    def new
      puts "Creating new blank Praxis app under #{app_name}"
      create_root_files
      create_config
      create_app
      create_design
      create_spec
    end
  
    private    
    def create_root_files
      ['config.ru','Gemfile','Guardfile','Rakefile','README.md'].each do |file|
        copy_file file, "#{app_name}/#{file}"
      end
    end
    
    def create_config
      copy_file "config/environment.rb", "#{app_name}/config/environment.rb"
      copy_file "config/rainbows.rb", "#{app_name}/config/rainbows.rb"
    end
    
    def create_app
      directory "app", "#{app_name}/app", :recursive => true
    end
        
    def create_design
      directory "design", "#{app_name}/design", :recursive => true
    end
    
    def create_spec
      directory "spec", "#{app_name}/spec", :recursive => true
    end
  
  end
end
