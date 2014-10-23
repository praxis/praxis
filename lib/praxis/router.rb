require 'mustermann/router/rack'

module Praxis

  class Router
    attr_reader :request_class, :application

    class VersionMatcher
      def initialize(target, version: 'n/a')
        @target = target
        @version = version
      end
      def call(request)
        if request.version(@target.action.resource_definition.version_options) == @version          
          @target.call(request)
        else
          # Version doesn't match, pass and continue
          request.unmatched_versions << @version
          throw :pass
        end
      end
    end
    
    class RequestRouter < Mustermann::Router::Simple      
      def initialize(default: nil, **options, &block)
        options[:default] = :not_found

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
      @routes = Hash.new do |hash, verb|
          hash[verb] = RequestRouter.new
      end
      @request_class = request_class
      @application = application
    end

    def add_route(target, route)
      warn 'other conditions not supported yet' if route.options.any?
      version_wrapper = VersionMatcher.new(target, version: route.version)    
      @routes[route.verb].on(route.path, call: version_wrapper)
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

      verb = request.verb
      result = @routes[verb].call(request)
      if result == :not_found
        # no need to try :path as we cannot really know if you've attempted to pass a version through it here
        # plus we wouldn't have tracked it as unmatched
        version = request.version(using: [:header,:params]) 
        attempted_versions = request.unmatched_versions
        body = "NotFound"
        unless attempted_versions.empty? || (attempted_versions.size == 1 && attempted_versions.first == 'n/a')
          body += if version == 'n/a' 
                    ". Your request did not specify an API version.".freeze 
                  else 
                    ". Your request speficied API version = \"#{version}\"."
                  end
          pretty_versions = attempted_versions.collect(&:inspect).join(', ')
          body += " Available versions = #{pretty_versions}."
        end
        result = [404, {"Content-Type" => "text/plain", }, [body]] 
      end
      result
    end

  end

end
