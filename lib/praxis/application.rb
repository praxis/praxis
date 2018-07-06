require 'singleton'
require 'mustermann'
require 'logger'

module Praxis
  class Application

    attr_reader :router
    attr_reader :controllers
    attr_reader :resource_definitions
    attr_reader :app
    attr_reader :builder

    attr_accessor :bootloader
    attr_accessor :file_layout
    attr_accessor :loaded_files
    attr_accessor :logger
    attr_accessor :plugins
    attr_accessor :doc_browser_plugin_paths
    attr_accessor :handlers
    attr_accessor :root
    attr_accessor :error_handler
    attr_accessor :validation_handler

    attr_accessor :versioning_scheme


    def self.instance
      i = $instance || Thread.current[:praxis_instance] 
      return i if i
      $instance = self.new
      $instance
    end
    
    def self.configure
      yield(self.instance)
    end

    def initialize
      @controllers = Set.new
      @resource_definitions = Set.new

      @error_handler = ErrorHandler.new
      @validation_handler = ValidationHandler.new

      @router = Router.new(self)

      @builder = Rack::Builder.new
      @app = nil

      @bootloader = Bootloader.new(self)
      @file_layout = nil
      @plugins = Hash.new
      @doc_browser_plugin_paths = []
      @handlers = Hash.new
      @loaded_files = Set.new
      @config = Config.new
      @root = nil
      @logger = Logger.new(STDOUT)
    end


    def setup(root: '.')

      return self unless @app.nil?
      @root = Pathname.new(root).expand_path

      builtin_handlers = {
        'plain' => Praxis::Handlers::Plain,
        'json' => Praxis::Handlers::JSON,
        'x-www-form-urlencoded' => Praxis::Handlers::WWWForm
      }
      
      # Register built-in handlers unless the app already provided its own
      builtin_handlers.each_pair do |name, handler|
        self.handler(name, handler) unless handlers.key?(name)
      end

      bootloader.setup!
      builder.run(@router)
      @app = builder.to_app

      Notifications.subscribe 'rack.request.all'.freeze do |name, start, finish, _id, payload|
        duration = (finish - start) * 1000
        Stats.timing(name, duration)

        status, _, _ = payload[:response]
        Stats.increment "rack.request.#{status}"
      end
      self
    end

    def middleware(middleware, *args, &block)
      @builder.use(middleware, *args, &block)
    end

    # Register a media type handler used to transform medias' structured data
    # to HTTP response entitites with a specific encoding (JSON, XML, etc)
    # and to parse request bodies into structured data.
    #
    # @param [String] name
    # @param [Class] a class that responds to .new, #parse and #generate

    def handler(name, handler)
      # Construct an instance, if the handler is a class and needs to be initialized.
      handler = handler.new

      # Make sure it quacks like a handler.
      unless handler.respond_to?(:generate) && handler.respond_to?(:parse)
        raise ArgumentError, "Media type handlers must respond to #generate and #parse"
      end

      # Register that thing!
      @handlers[name.to_s] = handler
    end

    def call(env)
      response = []
      Notifications.instrument 'rack.request.all'.freeze, response: response do
        response.push(*@app.call(env))
      end
    end

    def layout(&block)
      self.file_layout = FileGroup.new(self.root, &block)
    end

    def config(key=nil, type=Attributor::Struct, **opts, &block)
      if block_given? || (type==Attributor::Struct && !opts.empty? )
        @config.define(key, type, opts, &block)
      else
        @config.get
      end
    end

    def config=(config)
      @config.set(config)
    end

  end
end
