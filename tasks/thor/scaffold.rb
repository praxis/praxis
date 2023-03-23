# frozen_string_literal: true

module PraxisGen
  class Scaffold < Thor
    require 'active_support/inflector'
    include Thor::Actions

    attr_reader :actions_hash

    def self.source_root
      "#{File.dirname(__FILE__)}/templates/generator/scaffold"
    end

    desc 'g', 'Generates an API design and implementation scaffold for managing a collection of <collection_name>'
    argument :collection_name, required: true
    option :base, required: false,
                  desc: 'Module name to enclose all generated files. Empty by default. You can pass things like MyApp, or MyApp::SubModule'
    option :version, required: false,
                     desc: 'Version string for the API endpoint. This also dictates the directory structure (i.e., v1/endpoints/...))'
    option :design, type: :boolean, default: true,
                    desc: 'Include the Endpoint and MediaType files for the collection'
    option :implementation, type: :boolean, default: true,
                            desc: 'Include the Controller and (possibly the) Resource files for the collection (see --no-resource)'
    option :resource, type: :boolean, default: true,
                      desc: 'Disable (or enable) the creation of the Resource files when generating implementation'
    option :model, type: :string, enum: %w[activerecord sequel],
                   desc: 'It also generates a model for the given ORM. An empty --model flag will default to activerecord'
    option :actions, type: :string, default: 'crud', enum: %w[cr cru crud u ud d],
                     desc: 'Specifies the actions to generate for the API. cr=create, u=update, d=delete. Index and show actions are always generated'
    def g
      incorporate_config_options
      # Good defaults
      options[:version] = '1' unless options[:version].presence
      options[:models_dir] = 'app/models' unless options[:models_dir]

      self.class.check_name(collection_name)
      @actions_hash = self.class.compose_actions_hash(options[:actions])
      env_rb = Pathname.new(destination_root) + Pathname.new('config/environment.rb')
      @pagination_plugin_found = File.open(env_rb).grep(/Praxis::Plugins::PaginationPlugin.*/).reject { |l| l.strip[0] == '#' }.present?
      if options[:design]
        say_status 'Design', "Generating scaffold for #{plural_class}", :blue
        template 'design/media_types/item.rb', "design/#{version_dir}/media_types/#{collection_name.singularize}.rb"
        template 'design/endpoints/collection.rb', "design/#{version_dir}/endpoints/#{collection_name}.rb"
      end
      if options[:implementation]
        say_status 'Implement', "Generating scaffold for #{plural_class}", :blue
        if options[:resource]
          base_resource = Pathname.new(destination_root) + Pathname.new("app/#{version_dir}/resources/base.rb")
          unless base_resource.exist?
            # Copy an appropriate base resource for the version (resources within same version must share same base)
            say_status 'NOTE:',
                       "Creating a base resource file for resources to inherit from (at 'app/#{version_dir}/resources/base.rb')",
                       :yellow
            say_status '',
                       'If you had already other resources in the app, change them to derive from this Base'
            template 'implementation/resources/base.rb', "app/#{version_dir}/resources/base.rb"
          end
          template 'implementation/resources/item.rb', "app/#{version_dir}/resources/#{collection_name.singularize}.rb"
        end
        template 'implementation/controllers/collection.rb', "app/#{version_dir}/controllers/#{collection_name}.rb"
      end
      nil
      save_last_config_options
    end

    # Helper functions (which are available in the ERB contexts)
    no_commands do
      def incorporate_config_options
        @saved_original_options = options
        self.options = options.dup
        return if PraxisGenerator.scaffold_config.empty?

        begin
          options[:base] = PraxisGenerator.scaffold_config[:base] unless PraxisGenerator.scaffold_config[:base].presence
          options[:version] = PraxisGenerator.scaffold_config[:version] unless PraxisGenerator.scaffold_config[:version].presence
          options[:models_dir] = PraxisGenerator.scaffold_config[:models_dir] if PraxisGenerator.scaffold_config[:models_dir]
        rescue StandardError # rubocop:disable Lint/SuppressedException
        end
      end

      def save_last_config_options
        return if @saved_original_options.slice('base', 'version').empty?

        opts_to_save = options.slice('base', 'version').transform_keys(&:to_sym).reject{|k,v| v.nil?}
        PraxisGenerator.scaffold_config.merge!(opts_to_save)
      end

      def plural_class
        collection_name.camelize
      end

      def singular_class
        collection_name.singularize.camelize
      end

      def base_module
        options[:base]
      end

      def version
        options[:version]
      end

      def version_module
        base_module.presence ? "#{base_module}::V#{version}" : "V#{version}"
      end

      def version_dir
        "v#{version}"
      end

      def action_enabled?(action)
        @actions_hash[action.to_sym]
      end

      def pagination_enabled?
        @pagination_plugin_found
      end
    end

    def self.compose_actions_hash(actions_opt)
      required = { index: true, show: true }
      case actions_opt
      when nil
        required
      when 'cr'
        required.merge(create: true)
      when 'cru'
        required.merge(create: true, update: true)
      when 'crud'
        required.merge(create: true, update: true, delete: true)
      when 'u'
        required.merge(update: true)
      when 'ud'
        required.merge(update: true, delete: true)
      when 'd'
        required.merge(delete: true)
      else
        raise "actions option does not support the string #{actions_opt}"
      end
    end

    def self.check_name(name)
      sanitized = name.downcase.gsub(/[^a-z0-9_]/, '')
      # TODO: bail or support CamelCase collections (for now only snake case)
      raise 'Please use only downcase letters, numbers and underscores for the collection' unless sanitized == name
    end
  end
end
