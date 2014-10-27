require 'singleton'

require 'harness'

module Praxis

  module Stats
    include Praxis::PluginConcern

    class Statsd < ::Statsd
      def initialize(host: '127.0.0.1', port: 8125, prefix: nil, postfix: nil)
        self.host = host
        self.port = port
        self.namespace = prefix if prefix
        self.postfix = postfix
        @batch_size = 10
      end
    end

    class Plugin < Praxis::Plugin
      include Singleton

      def initialize
        @options = {config_file: 'config/stats.yml'}
      end

      def config_key
        :stats # 'praxis.stats'
      end

      def prepare_config!(node)
        node.attributes do
          attribute :collector, Hash, default: {type: 'Harness::FakeCollector'} do
            key :type, String, required: true
            key :args, Hash
          end
          attribute :queue, Hash, default: {type: 'Harness::AsyncQueue' } do
            key :type, String, required: true
            key :args, Hash
          end
        end
      end

      def setup!
        Harness.config.collector = load_type(config.collector)
        Harness.config.queue = load_type(config.queue)
      end

      def load_type(hash)
        type = hash[:type].constantize
        args = hash[:args]
        case args
        when Attributor::Hash
          type.new(**args.contents.symbolize_keys)
        when Hash
          type.new(**args.symbolize_keys)
        when nil
          type.new
        else
          raise "unknown args type: #{args.class.name}"
        end
      end

    end


    def self.collector
      Harness.collector
    end

    def self.config
      Harness.config
    end

    def self.queue
      Harness.queue
    end

    def self.count(*args)
      Harness.count(*args)
    end

    def self.decrement(*args)
      Harness.decrement(*args)
    end

    def self.gauge(*args)
      Harness.gauge(*args)
    end

    def self.increment(*args)
      Harness.increment(*args)
    end

    def self.time(stat, sample_rate = 1, &block)
      Harness.time(stat, sample_rate, &block)
    end

    def self.timing(*args)
      Harness.timing(*args)
    end


  end

end
