require 'singleton'
require 'mustermann'
require 'logger'

module Praxis
  class Application
    include Singleton

    attr_reader :router
    attr_reader :controllers
    attr_reader :resource_definitions

    attr_accessor :bootloader
    attr_accessor :file_layout
    attr_accessor :loaded_files
    attr_accessor :logger
    attr_accessor :plugins
    attr_accessor :root

    def self.configure
      yield(self.instance)
    end

    def initialize
      @controllers = Set.new
      @resource_definitions = Set.new

      @router = Router.new(self)

      @bootloader = Bootloader.new(self)
      @file_layout = nil
      @plugins = Array.new
      @loaded_files = Set.new
      @config = Config.new
      @root = nil
      @logger = Logger.new(STDOUT)
    end
    
    def setup(root: '.')
      @root = Pathname.new(root).expand_path

      @bootloader.setup!
      self
    end

    def call(env)
      self.router.call(env)
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
