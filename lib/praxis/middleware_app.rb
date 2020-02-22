module Praxis
  class MiddlewareApp

    attr_reader :target

    # Initialize the application instance with the desired args, and return the wrapping class.
    def self.for( **args )
      Class.new(self) do
        @args = args
        @setup_done = false
        def self.name
          'MiddlewareApp'
        end
        def self.args
          @args
        end
        def self.setup_done
          @setup_done
        end
        def self.setup
          @setup_done = true
          Praxis::Application.instance.setup(**@args)
        end
      end
     end

    def initialize( inner )
      @target = inner
      @setup_done = false
    end

    def call(env)
      self.class.setup unless self.class.setup_done
      
      result = Praxis::Application.instance.call(env)

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