require 'praxis-mapper'
require 'singleton'

require 'terminal-table'

# Plugin for applications which use the 'praxis-mapper' gem.
#
# This plugin provides the following features:
#   1. Sets up the PraxisMapper::IdentityMap for your application and assigns
#      it to the Praxis::Application.instance.request.identity_map for access
#      from your application.
#   2. Connects to your database and dumps a log of database interaction stats
#      (if enabled via the :log_stats option).
#
# This plugin accepts one of the following options:
#   1. db_config: A Hash containing the configs for the database repositories
#      queried through praxis-mapper. This parameter is a Hash where a key
#      is the identifiers for a repository and the value is the options one
#      would give to the 'sequel' gem. For example:
#           db_config: {
#             default: {
#               host: 127.0.0.1,
#               username: root,
#               password: nil,
#               database: myapp_dev,
#               adapter: mysql2
#             }
#           }
#   2. scope: A Hash containing scopes for the plugin to provide to the
#      PraxisMapper::IdentityMap created.
#   3. log_stats: A Boolean flag indicating whether or not to dump DB stats to
#      the Praxis::Application.instance.logger app log.
#   4. config_file: A String indicating the path where this plugin's config
#      file exists.
#
# See http://praxis-framework.io/reference/plugins/ for further details on how
# to use a plugin.
#
module Praxis
  module Plugins
    module PraxisMapperPlugin
      include Praxis::PluginConcern

      class RepositoryConfig < Attributor::Hash
        self.key_type = String

        keys allow_extra: true do
          key 'type', String, default: 'sequel'
          extra 'connection_settings'
        end

      end


      class Plugin < Praxis::Plugin
        include Singleton

        def initialize
          @options = {
            config_file: 'config/praxis_mapper.yml',
            scopes: {},
            log_stats: false
          }
        end

        def config_key
          :praxis_mapper
        end

        def prepare_config!(node)
          node.attributes do
            attribute :log_stats, String, values: ['detailed', 'short', 'skip'], default: 'detailed'
            attribute :repositories, Attributor::Hash.of(key: String, value: RepositoryConfig)
          end
        end

        # Make our own custom load_config! method
        def load_config!
          return unless options.has_key?(:config_file)
          config_file_path = application.root + options[:config_file]
          return {} unless config_file_path.exist?

          YAML.load_file(config_file_path).merge(repositories: options[:db_config])
        end

        def setup!
          self.config.repositories.each do |repository_name, repository_config|
            type = repository_config['type']
            connection_settings = repository_config['connection_settings']

            case type
            when 'sequel'
              self.setup_sequel_repository(repository_name, connection_settings)
            else
              raise "unsupported repository type: #{type}"
            end

          end

          Praxis::Notifications.subscribe 'praxis.request.all' do |name, *junk, payload|
            if (identity_map = payload[:request].identity_map)
              PraxisMapperPlugin::Statistics.log(identity_map) if @options[:log_stats]
            end
          end

        end

        def setup_sequel_repository(name, settings)
          db = Sequel.connect(settings.dump.symbolize_keys)

          Praxis::Mapper::ConnectionManager.setup do
            repository(name.to_sym) { db }
          end
        end

      end

      module Request
        def identity_map
          @identity_map
        end

        def identity_map=(map)
          @identity_map = map
        end
      end

      module Controller
        extend ActiveSupport::Concern

        included do
          before :action do |controller|
            controller.request.identity_map = Praxis::Mapper::IdentityMap.setup!
          end
        end
      end

      module Statistics

        def self.log(identity_map)
          return if identity_map.nil?
          case PraxisMapperPlugin::Plugin.instance.config.log_stats
          when 'detailed'
            self.detailed(identity_map)
          when 'short'
            self.short(identity_map)
          when 'skip'
          end
        end

        def self.detailed(identity_map)
          stats_by_model = identity_map.query_statistics.sum_totals_by_model
          stats_total = identity_map.query_statistics.sum_totals
          fields = [ :query_count, :records_loaded, :datastore_interactions, :datastore_interaction_time]
          rows = []

          total_models_loaded = 0
          # stats per model
          stats_by_model.each do |model, totals|
            total_values = totals.values_at(*fields)
            self.round_fields_at( total_values , [fields.index(:datastore_interaction_time)])
            row = [ model ] + total_values
            models_loaded = identity_map.all(model).size
            total_models_loaded += models_loaded
            row << models_loaded
            rows << row
          end

          rows << :separator

          # totals for all models
          stats_total_values = stats_total.values_at(*fields)
          self.round_fields_at(stats_total_values , [fields.index(:datastore_interaction_time)])
          rows << [ "All Models" ] + stats_total_values + [total_models_loaded]

          table = Terminal::Table.new \
            :rows => rows,
            :title => "Praxis::Mapper Statistics",
            :headings => [ "Model", "# Queries", "Records Loaded", "Interactions", "Time(sec)", "Models Loaded" ]

          table.align_column(1, :right)
          table.align_column(2, :right)
          table.align_column(3, :right)
          table.align_column(4, :right)
          table.align_column(5, :right)
          Praxis::Application.instance.logger.info "Praxis::Mapper Statistics:\n#{table.to_s}"
        end

        def self.round_fields_at(values, indices)
          indices.each do |idx|
            values[idx] = "%.3f" % values[idx]
          end
        end

        def self.short(identity_map)
          Praxis::Application.instance.logger.info "Praxis::Mapper Statistics: #{identity_map.query_statistics.sum_totals.to_s}"
        end

      end

    end
  end
end
