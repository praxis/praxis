# frozen_string_literal: true

require 'singleton'
require 'mustermann'
require 'logger'

module Praxis
  class Application
    include Singleton

    attr_reader :router, :controllers, :endpoint_definitions, :app, :builder

    attr_accessor :bootloader, :file_layout, :loaded_files, :logger, :plugins, :doc_browser_plugin_paths, :handlers, :root, :error_handler, :validation_handler, :versioning_scheme

    def self.configure
      yield(instance)
    end

    def initialize
      @controllers = Set.new
      @endpoint_definitions = Set.new

      @error_handler = ErrorHandler.new
      @validation_handler = ValidationHandler.new

      @router = Router.new(self)

      @builder = Rack::Builder.new
      @app = nil

      @bootloader = Bootloader.new(self)
      @file_layout = nil
      @plugins = {}
      @doc_browser_plugin_paths = []
      @handlers = {}
      @loaded_files = Set.new
      @config = Config.new
      @root = nil
      @logger = Logger.new($stdout)
    end

    def setup(root: '.')
      return self unless @app.nil?

      @root = Pathname.new(root).expand_path

      builtin_handlers = {
        'plain' => Praxis::Handlers::Plain,
        'json' => Praxis::Handlers::JSON
      }
      # Register built-in handlers unless the app already provided its own
      builtin_handlers.each_pair do |name, handler|
        self.handler(name, handler) unless handlers.key?(name)
      end

      @bootloader.setup!

      @builder.run(@router)
      @app = @builder.to_app

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
      raise ArgumentError, 'Media type handlers must respond to #generate and #parse' unless handler.respond_to?(:generate) && handler.respond_to?(:parse)

      # Register that thing!
      @handlers[name.to_s] = handler
    end

    def call(env)
      response = []
      Notifications.instrument 'rack.request.all', response: response do
        response.push(*@app.call(env))
      end
    end

    def layout(&block)
      self.file_layout = FileGroup.new(root, &block)
    end

    def config(key = nil, type = Attributor::Struct, **opts, &block)
      if block_given? || (type == Attributor::Struct && !opts.empty?)
        @config.define(key, type, **opts, &block)
      else
        @config.get
      end
    end

    def config=(config)
      @config.set(config)
    end

    # [DEPRECATED] - Warn of the change of method name for the transition
    def resource_definitions
      raise 'Praxis::Application.instance does not use `resource_definitions` any longer. Use `endpoint_definitions` instead.'
    end
  end
end
