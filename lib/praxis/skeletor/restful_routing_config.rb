module Praxis
  module Skeletor
    class RestfulRoutingConfig

      attr_reader :name, :controller_config, :routes

      def initialize(name, controller_config, &block)
        @name = name
        @controller_config = controller_config
        @routes = []

        @prefix = "/" + controller_config.name.split("::").last.underscore


        if controller_config.routing_config
          instance_eval(&controller_config.routing_config)
        end


        instance_eval(&block)
      end

      def prefix(prefix=nil)
        return @prefix unless prefix
        @prefix = prefix
      end

      def get(path, opts={})     add_route 'GET',     path, opts end
      def put(path, opts={})     add_route 'PUT',     path, opts end
      def post(path, opts={})    add_route 'POST',    path, opts end
      def delete(path, opts={})  add_route 'DELETE',  path, opts end
      def head(path, opts={})    add_route 'HEAD',    path, opts end
      def options(path, opts={}) add_route 'OPTIONS', path, opts end
      def patch(path, opts={})   add_route 'PATCH',   path, opts end


      def add_route(verb, path, options={})
        if path.respond_to?(:to_str)
          path = "#{@prefix}#{path.to_str}"
        end
        @routes << [verb, path, options]
      end

      def urls
        @routes.collect do | (verb, path, options)|
          [verb, path]
        end
      end

    end

  end
end
