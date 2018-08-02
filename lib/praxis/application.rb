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
    attr_reader :api_definition

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

    def print_me
      ">>>0x#{(self.object_id << 1).to_s(16)}"
    end
    
    def self.instance
      i = $praxis_initializing_instance || Thread.current[:praxis_instance] 
      return i if i
      $praxis_initializing_instance = self.new
      puts "Praxis: New instance #{$praxis_initializing_instance.print_me}"      
      $praxis_initializing_instance
    end
    
    def self.configure
      yield(self.instance)
    end

    def initialize
      puts "Praxis: initialize #{print_me}"
      old = $praxis_initializing_instance
      $praxis_initializing_instance = self # ApiDefinition.new needs to get the instance...
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
      @api_definition = ApiDefinition.new
      
      @api_definition.define do |api|
        api.response_template :ok do |media_type: , location: nil, headers: nil, description: nil |
          status 200
          description( description || 'Standard response for successful HTTP requests.' )

          media_type media_type
          location location
          headers headers if headers
        end

        api.response_template :created do |media_type: nil, location: nil, headers: nil, description: nil|
          status 201
          description( description || 'The request has been fulfilled and resulted in a new resource being created.' )

          media_type media_type if media_type
          location location
          headers headers if headers
        end
      end
      
      $praxis_initializing_instance = old
    end


    def setup(root: '.')
      return self unless @app.nil?
      saved_value = $praxis_initializing_instance
      $praxis_initializing_instance = self
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

      require 'praxis/responses/http'
      require 'praxis/responses/internal_server_error'
      require 'praxis/responses/validation_error'
      require 'praxis/responses/multipart_ok'

      bootloader.setup!
      builder.run(@router)
      @app = builder.to_app

      Notifications.subscribe 'rack.request.all'.freeze do |name, start, finish, _id, payload|
        duration = (finish - start) * 1000
        Stats.timing(name, duration)

        status, _, _ = payload[:response]
        Stats.increment "rack.request.#{status}"
      end
      $praxis_initializing_instance = saved_value
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
      old = Thread.current[:praxis_instance]
      Thread.current[:praxis_instance] = self
      Notifications.instrument 'rack.request.all'.freeze, response: response do
        response.push(*@app.call(env))
      end
    ensure
      Thread.current[:praxis_instance] = old      
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
