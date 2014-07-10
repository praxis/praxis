module Praxis
  module Skeletor
    class RestfulRoutingConfig

      attr_reader :name, :resource_definition, :routes

      def initialize(name, resource_definition, &block)
        @name = name
        @resource_definition = resource_definition
        @routes = []

        @prefix = "/" + resource_definition.name.split("::").last.underscore

        if resource_definition.routing_config
          instance_eval(&resource_definition.routing_config)
        end

        instance_eval(&block)
      end

      def prefix(prefix=nil)
        return @prefix unless prefix
        @prefix = prefix
      end

      def options(path, opts={}) add_route 'OPTIONS', path, opts end
      def get(path, opts={})     add_route 'GET',     path, opts end
      def head(path, opts={})    add_route 'HEAD',    path, opts end
      def post(path, opts={})    add_route 'POST',    path, opts end
      def put(path, opts={})     add_route 'PUT',     path, opts end
      def delete(path, opts={})  add_route 'DELETE',  path, opts end
      def trace(path, opts={})   add_route 'TRACE',   path, opts end
      def connect(path, opts={}) add_route 'CONNECT', path, opts end
      def patch(path, opts={})   add_route 'PATCH',   path, opts end

      def add_route(verb, path, options={})
        path = Mustermann.new(@prefix + path)

        @routes << Route.new(verb, path, resource_definition.version, **options)
      end

    end

  end
end
