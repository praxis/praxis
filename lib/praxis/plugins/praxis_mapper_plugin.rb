require 'praxis-mapper'
require 'singleton'

require 'terminal-table'

# Plugin for applications which use the 'praxis-mapper' gem.
#
# This plugin provides the following features:
#   1. Sets up the PraxisMapper::IdentityMap for your application and assigns
#      it to the controller's request.identity_map for access from your
#      application.
#   2. Connects to your database and dumps a log of database interaction stats
#      (if enabled via the :log_stats option).
#
# This plugin accepts one of the following options:
#   1. config_file: A String indicating the path where this plugin's config
#      file exists.
#   2. config_data: A Hash of data that is merged into the YAML hash loaded
#      from config_file.
#
# The config_data Hash contains the following keys:
#   1. repositories: A Hash containing the configs for the database repositories
#      queried through praxis-mapper. This parameter is a Hash where a key is
#      the identifier for a repository and the value is the options one
#      would give to the 'sequel' gem. For example:
#           repositories: {
#             default: {
#               host: 127.0.0.1,
#               username: root,
#               password: nil,
#               database: myapp_dev,
#               adapter: mysql2
#             }
#           }
#   2. log_stats: A String indicating what kind of DB stats you would like
#      output into the Praxis::Application.instance.logger app log. Possible
#      values are: "detailed", "short", and "skip" (i.e. do not print the stats
#      at all).
#
# See http://praxis-framework.io/reference/plugins/ for further details on how
# to use a plugin and pass it options.
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
            config_data: {
              repositories: {}
            }
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
          config_file_path = application.root + options[:config_file]
          result = config_file_path.exist? ? YAML.load_file(config_file_path) : {}
          result.merge(@options[:config_data])
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

          log_stats = PraxisMapperPlugin::Plugin.instance.config.log_stats
          unless log_stats == 'skip'
            Praxis::Notifications.subscribe 'praxis.request.all' do |name, *junk, payload|
              if (identity_map = payload[:request].identity_map)
                PraxisMapperPlugin::Statistics.log(identity_map, log_stats)
              end
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
            controller.request.identity_map = Praxis::Mapper::IdentityMap.new
          end
        end
      end

      module Statistics

        def self.log(identity_map, log_stats)
          return if identity_map.nil?
          if identity_map.queries.empty?
            Praxis::Application.instance.logger.debug "Praxis::Mapper Statistics: No database interactions observed."
            return
          end
          case log_stats
          when 'detailed'
            self.detailed(identity_map)
          when 'short'
            self.short(identity_map)
          when 'skip'
            # Shouldn't receive this. But anyway...no-op.
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
          Praxis::Application.instance.logger.debug "Praxis::Mapper Statistics:\n#{table.to_s}"
        end

        def self.round_fields_at(values, indices)
          indices.each do |idx|
            values[idx] = "%.3f" % values[idx]
          end
        end

        def self.short(identity_map)
          Praxis::Application.instance.logger.debug "Praxis::Mapper Statistics: #{identity_map.query_statistics.sum_totals.to_s}"
        end
      end
    end
  end
end
