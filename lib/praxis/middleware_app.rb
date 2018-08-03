module Praxis
  class MiddlewareApp

    attr_reader :target
    # Initialize the application instance with the desired args, and return the wrapping class.
    def self.for( **args )
      Class.new(self) do
        class << self
          attr_accessor :app_instance
          attr_reader :app_name
        end
        @app_name = args.delete(:name)
        @args = args
        @app_instance = nil
        
        def self.name
          'MiddlewareApp'
        end
        def self.args
          @args
        end
        def self.setup
          puts "SETTING UP CLASS!!!#{args}" 
          app_instance.setup(**args)
        end
      end
    end

    def initialize( inner )
      puts "SELF: #{self}"
      @target = inner
      self.class.app_instance = Praxis::Application.new(name: self.class.app_name)
      
      #$josep_hack_mware = self
    end
    
    def call(env)
      # NOTE: Need to make sure somebody has properly called the setup above before this is called
      #@app_instance ||= Praxis::Application.new.setup(**self.class.args) #I Think that's not right at all...
      result = self.class.app_instance.call(env)

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