require 'singleton'
require 'mustermann'

module Praxis
  class Application
    include Singleton

    attr_reader :router, :controllers
    attr_accessor :file_layout, :root, :config, :bootloader, :plugins, :loaded_files

    def initialize
      @controllers = Set.new
      @router = Router.new

      @bootloader = Skeletor::Bootloader.new(self)
      @file_layout = nil
      @plugins = Array.new
      @loaded_files = Set.new
      @config = Hash.new
      @root = nil
    end


    def setup(root: '.')
      @root = Pathname.new(root).expand_path

      @bootloader.setup!
    end

    def call(env)
      self.router.call(env)
    end

  end
end
