# frozen_string_literal: true

module Praxis
  CONTEXT_FOR = {
    params: [Attributor::ROOT_PREFIX, 'params'],
    headers: [Attributor::ROOT_PREFIX, 'headers'],
    payload: [Attributor::ROOT_PREFIX, 'payload']
  }.freeze

  class Dispatcher
    attr_reader :controller, :action, :request, :application

    @deferred_callbacks = Hash.new do |hash, stage|
      hash[stage] = { before: [], after: [] }
    end

    class << self
      attr_reader :deferred_callbacks
    end

    def self.before(*_stage_path, **conditions, &block)
      @deferred_callbacks[:before] << [conditions, block]
    end

    def self.after(*_stage_path, **conditions, &block)
      @deferred_callbacks[:after] << [conditions, block]
    end

    def self.current(thread: Thread.current, application: Application.instance)
      thread[:praxis_dispatcher] ||= new(application: application)
    end

    def initialize(application: Application.instance)
      @stages = []
      @application = application
      setup_stages!
    end

    def setup_stages!
      @stages << RequestStages::LoadRequest.new(:load_request, self)
      @stages << RequestStages::Validate.new(:validate, self)
      @stages << RequestStages::Action.new(:action, self)
      @stages << RequestStages::Response.new(:response, self)
      @stages.each do |s|
        s.setup!
      end
      setup_deferred_callbacks!
    end

    def setup_deferred_callbacks!
      self.class.deferred_callbacks.each do |stage_name, callbacks|
        callbacks[:before].each do |(*stage_path, block)|
          before(stage_name, *stage_path, &block)
        end

        callbacks[:after].each do |(*stage_path, block)|
          after(stage_name, *stage_path, &block)
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

      payload = { request: request, response: nil, controller: @controller }

      instrumented_dispatch(payload)
    ensure
      @controller = nil
      @action = nil
      @request = nil
    end

    def instrumented_dispatch(payload)
      Notifications.instrument 'praxis.request.all', payload do
        # the response stage must be the final stage in the list
        *stages, response_stage = @stages

        stages.each do |stage|
          result = stage.run
          case result
          when Response
            controller.response = result
            break
          end
        end

        response_stage.run

        payload[:response] = controller.response
        controller.response.finish
      rescue StandardError => e
        @application.error_handler.handle!(request, e)
      end
    end

    # TODO: fix for multithreaded environments
    def reset_cache!
      return unless Praxis::Blueprint.caching_enabled?

      Praxis::Blueprint.cache = Hash.new do |hash, key|
        hash[key] = {}
      end
    end
  end
end
