require 'singleton'
require 'mustermann'
require 'logger'

module Praxis
  class Application
    include Singleton

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
    attr_accessor :root
    attr_accessor :error_handler


    def self.configure
      yield(self.instance)
    end

    def initialize
      @controllers = Set.new
      @resource_definitions = Set.new

      @error_handler = ErrorHandler.new

      @router = Router.new(self)

      @builder = Rack::Builder.new
      @app = nil

      @bootloader = Bootloader.new(self)
      @file_layout = nil
      @plugins = Hash.new
      @loaded_files = Set.new
      @config = Config.new
      @root = nil
      @logger = Logger.new(STDOUT)
    end
    
    def setup(root: '.')
      @root = Pathname.new(root).expand_path

      @bootloader.setup!

      @builder.run(@router)
      @app = @builder.to_app

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
