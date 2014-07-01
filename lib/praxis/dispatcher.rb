module Praxis

  CONTEXT_FOR = {
    params: [Attributor::AttributeResolver::ROOT_PREFIX, "params".freeze],
    headers: [Attributor::AttributeResolver::ROOT_PREFIX, "headers".freeze],
    payload: [Attributor::AttributeResolver::ROOT_PREFIX, "payload".freeze]
  }.freeze

  class Dispatcher
    attr_reader :controller, :action, :request

    @deferred_callbacks = Hash.new do |hash,stage|
      hash[stage] = {before: [], after:[]}
    end

    class << self
      attr_reader :deferred_callbacks
    end

    def self.before(*stage_path, **conditions, &block)
      @deferred_callbacks[:before] << [conditions, block]
    end

    def self.after(*stage_path, **conditions, &block)
      @deferred_callbacks[:after] << [conditions, block]
    end


    def initialize
      @stages = []
      setup_stages!
    end

    def setup_stages!
      @stages << RequestStages::LoadRequest.new(:load_request, self)
      @stages << RequestStages::Validate.new(:validate, self)
      @stages << RequestStages::Action.new(:action, self)
      @stages << RequestStages::Response.new(:response, self)
      setup_deferred_callbacks!
    end

    def setup_deferred_callbacks!
      self.class.deferred_callbacks.each do |stage_name, callbacks|
        callbacks[:before].each do |(*stage_path, block)|
          self.before(stage_name, *stage_path, &block)
        end

        callbacks[:after].each do |(*stage_path, block)|
          self.after(stage_name, *stage_path, &block)
        end
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

    def dispatch(controller_class, action, request)
      @controller = controller_class.new(request)
      @action = action
      @request = request

      @stages.each do |stage|
        stage.run
      end

      controller.response.to_rack
    ensure
      @controller = nil
      @action = nil
      @request = nil
    end


  end
end
