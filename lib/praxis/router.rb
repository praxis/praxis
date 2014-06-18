require 'mustermann/router/rack'

module Praxis

  class Router

    def initialize
      @routes = Hash.new do |hash, key|
        hash[key] = Mustermann::Router::Rack.new(params_key: 'rack.routing_args')
      end
    end

    def add_route(target, path_info:, request_method:'GET', **conditions)
      warn 'conditions not supported yet' if conditions.any?
      @routes[request_method].on(path_info, call: target)
    end

    def call(env)
      verb = env['REQUEST_METHOD'.freeze]
      @routes[verb].call(env)
    end

  end

end
