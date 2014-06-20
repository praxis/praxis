module Skeletor

  # one instance is created per use.
  class Plugin

    attr_reader :application, :block

    def initialize(application, &block)
      @application = application
      @block = block
    end

    def config
      @application.config
    end

    def setup!
    end

    def after(stage,&block)
      application.bootloader.after(stage,&block)
    end

    def before(stage,&block)
      application.bootloader.before(stage,&block)
    end


  end
end