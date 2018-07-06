module Praxis
  class MiddlewareApp

    attr_reader :target

    # Initialize the application instance with the desired args, and return the wrapping class.
    def self.for( **args )
      Class.new(self) do

        @args = args
        def self.name
          'MiddlewareApp'
        end
        def self.args
          @args
        end
      end
     end

    def initialize( inner )
      @target = inner
      @app_instance = false
    end

    def call(env)
      @app_instance ||= Praxis::Application.new.setup(**self.class.args)
      result = @app_instance.call(env)

      unless ( [404,405].include?(result[0].to_i) && result[1]['X-Cascade'] == 'pass' )
        # Respect X-Cascade header if it doesn't specify 'pass'
        result
      else
        last_body = result[2]
        last_body.close if last_body.respond_to? :close
        target.call(env)
      end
    end

  end
end