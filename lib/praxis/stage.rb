module Praxis

  class Stage

    attr_reader :name, :context, :stages, :before_callbacks, :after_callbacks

    def application
      context
    end
    
    def initialize(name, context,**opts)
      @name = name
      @context = context
      @before_callbacks = Array.new
      @after_callbacks = Array.new
      @deferred_callbacks = Hash.new do |hash,stage|
        hash[stage] = {before: [], after:[]}
      end
      @stages = Array.new
    end

    def run
      setup!
      setup_deferred_callbacks!
      execute_callbacks(self.before_callbacks)
      execute
      execute_callbacks(self.after_callbacks)
    end

    def setup!
    end

    def setup_deferred_callbacks!
      @deferred_callbacks.keys.each do |stage_name|
        callbacks = @deferred_callbacks.delete stage_name
        callbacks[:before].each do |(*stage_path, block)|
          self.before(stage_name, *stage_path, &block)
        end

        callbacks[:after].each do |(*stage_path, block)|
          self.after(stage_name, *stage_path, &block)
        end
      end
    end

    def execute
      raise NotImplementedError, 'subclass must implement Stage#execute' unless @stages.any?

      @stages.each do |stage|
        stage.run
      end
    end

    def execute_callbacks(callbacks)
      callbacks.each do |callback|
        callback.call(callback_args, name: name)
      end
    end

    def callback_args
      nil
    end

    def before(*stage_path, &block)
      if stage_path.any?
        stage_name = stage_path.shift
        stage = stages.find { |stage| stage.name == stage_name }
        if stage
          stage.before(*stage_path, &block)
        else
          @deferred_callbacks[stage_name][:before] << [*stage_path, block]
        end
      else
        @before_callbacks << block
      end
    end

    def after(*stage_path, &block)
      if stage_path.any?
        stage_name = stage_path.shift
        stage = stages.find { |stage| stage.name == stage_name }
        if stage
          stage.after(*stage_path, &block)
        else
          @deferred_callbacks[stage_name][:after] << [*stage_path, block]
        end
      else
        @after_callbacks << block
      end
    end


  end
end
