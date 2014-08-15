module Praxis


  class Bootloader

    attr_reader :application, :stages

    def initialize(application)
      @application = application
      @stages = Array.new

      setup_stages!
    end

    def config
      @application.config
    end

    def root
      @application.root
    end

    def setup_stages!
      # Require environment first. they define constants and environment specific settings
      stages << BootloaderStages::Environment.new(:environment, application)

      # then the initializers. as it is their job to ensure monkey patches and other
      # config is in place first.
      stages << BootloaderStages::FileLoader.new(:initializers, application)

      # then require lib/ code.
      #stages << BootloaderStages::FileLoader.new(:lib, application)

      # app-specific code.
      stages << BootloaderStages::AppLoader.new(:app, application)

      # setup routing
      stages << BootloaderStages::Routing.new(:routing, application)

      # naggy warning about unloaded files
      stages << BootloaderStages::WarnUnloadedFiles.new(:warn_unloaded_files, application)
    end

    def delete_stage(stage_name)
      if (stage = stages.find { |stage| stage.name == stage_name })
        stages.delete(stage)
      else
        raise Exceptions::StageNotFound.new(
          "Cannot remove stage with name #{stage_name}, stage does not exist."
        )
      end
    end


    def before(*stage_path, &block)
      stage_name = stage_path.shift
      stages.find { |stage| stage.name == stage_name }.before(*stage_path, &block)
    end

    def after(*stage_path, &block)
      stage_name = stage_path.shift
      stages.find { |stage| stage.name == stage_name }.after(*stage_path, &block)
    end

    def use(plugin,&block)
      application.plugins << plugin.new(application, &block)
    end

    def setup!
      run
    end

    def run
      stages.each do |stage|
        stage.run
      end
    end

  end


end
