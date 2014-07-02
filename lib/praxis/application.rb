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

    def initialize
      @controllers = Set.new
      @resource_definitions = Set.new

      @router = Router.new

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
    end

    def call(env)
      self.router.call(env)
    end

    def config(&block)
      if block_given?
        @config.define(&block)
      else
        @config.get
      end
    end

    def config=(config)
      @config.set(config)
    end
  end
end
