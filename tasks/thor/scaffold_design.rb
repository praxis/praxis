# frozen_string_literal: true

module PraxisGen
  class Scaffold < Thor
    require 'active_support/inflector'
    include Thor::Actions
    
    def self.source_root
      File.dirname(__FILE__) + "/templates/generator/scaffold"
    end

    desc "g","Generates an API design and implementation scaffold for managing a collection of <collection_name>"
    argument :collection_name, required: true
    option :version, required: false, default: '1'
    option :design, type: :boolean, default: true
    option :implementation, type: :boolean,default: true
    option :resource, type: :boolean, default: true
    def g
      self.class.check_name(collection_name)

      if options[:design]
        puts "Generating Design scaffold for #{plural_class}"
        template 'design/media_types/item.rb', "design/#{version_dir}/media_types/#{collection_name.singularize}.rb"
        template 'design/endpoints/collection.rb', "design/#{version_dir}/endpoints/#{collection_name}.rb"
      end
      if options[:implementation]
        if options[:resource]
          template 'implementation/resources/item.rb', "app/#{version_dir}/resources/#{collection_name.singularize}.rb"
        end
        template 'implementation/controllers/collection.rb', "app/#{version_dir}/controllers/#{collection_name}.rb"
      end
      nil
    end

    # Helper functions (which are available in the ERB contexts)
    no_commands do
      def plural_class
        collection_name.camelize
      end
    
      def singular_class
        collection_name.singularize.camelize
      end
      
      def version
        options[:version]
      end

      def version_module
        "V#{version}"
      end
    
      def version_dir
        version_module.camelize(:lower)
      end
    end

    def self.check_name(name)
      sanitized = name.downcase.gsub(/[^a-z0-9_]/, '')
      # TODO: bail or support CamelCase collections (for now only snake case)
      raise "Please use only downcase letters, numbers and underscores for the collection" unless sanitized == name
    end
  end
end
