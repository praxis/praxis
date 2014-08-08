require 'mustermann/router/rack'

module Praxis

  class Router
    attr_reader :request_class, :application

    class RequestRouter < Mustermann::Router::Simple
      def initialize(default: nil, **options, &block)
        options[:default] = [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found"]] unless options.include? :default
        super(**options, &block)
      end

      def invoke(callback, request, params, pattern)
        request.route_params = params
        callback.call(request)
      end

      def string_for(request)
        request.path
      end
    end


    def initialize(application, request_class: Praxis::Request)
      @routes = Hash.new do |hash, version|
        hash[version] = Hash.new do |subhash, verb|
          subhash[verb] = RequestRouter.new
        end
      end
      @request_class = request_class
      @application = application
    end

    def add_route(target, route)
      warn 'other conditions not supported yet' if route.options.any?
      @routes[route.version][route.verb].on(route.path, call: target)
    end

    def call(env_or_request)
      request = case env_or_request
      when Hash
        request_class.new(env_or_request)
      when request_class
        env_or_request
      else
        raise ArgumentError, "received #{env_or_request.class}"
      end

      version = request.version
      verb = request.verb

      @routes[version][verb].call(request)
    end

  end

end
