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
      @app_instance = Praxis::Application.new
      $josep_hack_mware = self
    end

    def setup
      # This function is to allow the app initialization to set things up at the right time for now...
      # We need to have a better way to "reach" into the application instances from the middlewares registered 
      # in the bigger app...and call their setup... (this one...)
      puts "SETTING UP!!!#{self.class.args}" 
      @app_instance.setup(**self.class.args)
    end
    
    def call(env)
      # NOTE: Need to make sure somebody has properly called the setup above before this is called
      #@app_instance ||= Praxis::Application.new.setup(**self.class.args) #I Think that's not right at all...
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