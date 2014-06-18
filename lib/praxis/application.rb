require 'singleton'
require 'mustermann'

module Praxis
  class Application
    include Singleton

    CONTEXT_FOR = {
      params: [Attributor::AttributeResolver::ROOT_PREFIX, "params".freeze],
      headers: [Attributor::AttributeResolver::ROOT_PREFIX, "headers".freeze],
      payload: [Attributor::AttributeResolver::ROOT_PREFIX, "payload".freeze]
    }.freeze

    attr_reader :route_set, :controllers

    def initialize
      @controllers = Set.new
      @route_set = Router.new
    end

    def create_routes!
      controllers.each do |controller|
        controller.api_resource.actions.each do |name, action|
          action.routing_config.routes.each do |(verb, path, opts)|
            target = target_factory(controller, name)
            @route_set.add_route target, 
              path_info: Mustermann.new(path),
              request_method: verb
          end
        end
      end

      @route_set.freeze
    end

    def coalesce_inputs!(request)
      request.raw_params
      request.raw_payload
    end


    def load_headers(action, request)
      return unless action.headers
      defined_headers = action.headers.attributes.keys.each_with_object(Hash.new) do |name, hash|
        env_name = if name == :CONTENT_TYPE || name == :CONTENT_LENGTH
          name.to_s
        else
          "HTTP_#{name}"
        end
        hash[name] = request.env[env_name] if request.env.has_key? env_name
      end
      request.headers = action.headers.load(defined_headers,CONTEXT_FOR[:headers])
    end


    def load_params(action_config, request)
      request.params = action_config.params.load(request.raw_params)
    end


    def load_payload(action_config, request)
      request.payload = action_config.payload.load(request.raw_payload)
    end


    def validate_headers(request)
      return unless request.headers
      errors = request.headers.validate(CONTEXT_FOR[:headers])
      raise "nope: #{errors.inspect}" if errors.any?
    end


    def validate_params(request)
      errors = request.params.validate(CONTEXT_FOR[:params])
      raise "nope: #{errors.inspect}" if errors.any?
    end


    def validate_payload(request)
      errors = request.params.validate(CONTEXT_FOR[:payload])
      raise "nope: #{errors.inspect}" if errors.any?
    end

    def setup_request(action, request)
      coalesce_inputs!(request)

      load_headers(action, request)
      load_params(action, request)

      attribute_resolver = Attributor::AttributeResolver.new
      Attributor::AttributeResolver.current = attribute_resolver

      attribute_resolver.register("headers",request.headers)
      attribute_resolver.register("params",request.params)

      validate_headers(request)
      validate_params(request)

      # TODO: handle multipart requests
      if action.payload
        load_payload(action, request)
        attribute_resolver.register("payload",request.payload)
        validate_payload(request)
      end

      params = request.params_hash
      if action.payload
        params[:payload] = request.payload
      end

      params
    end


    def dispatch(controller, action, request)
      params = setup_request(action, request)

      controller_instance = controller.new(request)
      response = controller_instance.send(action.name, **params)

      if response.kind_of? String
        controller_instance.response.body = response
      else
        controller_instance.response = response
      end

      response = controller_instance.response

      response.handle
      response.validate(action)

      response.to_rack
    end


    def target_factory(controller, action_name)
      action = controller.action(action_name)

      unless (method = controller.instance_method(action_name))
        raise "No action with name #{action_name} defined on #{controller.name}"
      end

      Proc.new do |env|
        dispatch(controller, action, Praxis::Request.new(env))
      end
    end


    def call(env)
      self.route_set.call(env)
    end

  end
end
