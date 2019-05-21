require 'mustermann'
require 'logger'

module Praxis
  class Application

    attr_reader :router
    attr_reader :controllers
    attr_reader :resource_definitions
    attr_reader :app
    attr_reader :builder
    attr_reader :api_definition

    attr_accessor :bootloader
    attr_accessor :file_layout
    attr_accessor :loaded_files
    attr_accessor :logger
    attr_accessor :plugins
    attr_accessor :doc_browser_plugin_paths
    attr_accessor :handlers
    attr_accessor :root
    attr_accessor :error_handler
    attr_accessor :validation_handler

    attr_accessor :versioning_scheme

    @@registered_apps = {}

    def self.registered_apps
      @@registered_apps
    end
        
    def self.instance
      i = current_instance
      return i if i
      $praxis_initializing_instance = self.new
    end
    
    def self.current_instance
      Thread.current[:praxis_instance] || $praxis_initializing_instance
    end
    
    def self.configure
       # Should fail (i.e., be nil) if it's not in initialization/setup or a runtime call
      yield(current_instance)
    end

    def initialize(name: 'default', skip_registration: false)
      old = $praxis_initializing_instance
      $praxis_initializing_instance = self # ApiDefinition.new needs to get the instance...
      @controllers = Set.new
      @resource_definitions = Set.new

      @error_handler = ErrorHandler.new
      @validation_handler = ValidationHandler.new

      @router = Router.new(self)

      @builder = Rack::Builder.new
      @app = nil

      @bootloader = Bootloader.new(self)
      @file_layout = nil
      @plugins = Hash.new
      @doc_browser_plugin_paths = []
      @handlers = Hash.new
      @loaded_files = Set.new
      @config = Config.new
      @root = nil
      @logger = Logger.new(STDOUT)
      @api_definition = ApiDefinition.new(self)
      
      @api_definition.define do |api|
        api.response_template :ok do |media_type: , location: nil, headers: nil, description: nil |
          status 200
          description( description || 'Standard response for successful HTTP requests.' )

          media_type media_type
          location location
          headers headers if headers
        end

        api.response_template :created do |media_type: nil, location: nil, headers: nil, description: nil|
          status 201
          description( description || 'The request has been fulfilled and resulted in a new resource being created.' )

          media_type media_type if media_type
          location location
          headers headers if headers
        end
      end
      
      require 'praxis/responses/http'
      self.api_definition.define do |api|
        [
          [ :accepted, 202, "The request has been accepted for processing, but the processing has not been completed." ],
          [ :no_content, 204,"The server successfully processed the request, but is not returning any content."],
          [ :multiple_choices, 300,"Indicates multiple options for the resource that the client may follow."],
          [ :moved_permanently, 301,"This and all future requests should be directed to the given URI."],
          [ :found, 302,"The requested resource resides temporarily under a different URI."],
          [ :see_other, 303,"The response to the request can be found under another URI using a GET method"],
          [ :not_modified, 304,"Indicates that the resource has not been modified since the version specified by the request headers If-Modified-Since or If-Match."],
          [ :temporary_redirect, 307,"In this case, the request should be repeated with another URI; however, future requests should still use the original URI."],
          [ :bad_request, 400,"The request cannot be fulfilled due to bad syntax."],
          [ :unauthorized, 401,"Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided."],
          [ :forbidden, 403,"The request was a valid request, but the server is refusing to respond to it."],
          [ :not_found, 404,"The requested resource could not be found but may be available again in the future."],
          [ :method_not_allowed, 405,"A request was made of a resource using a request method not supported by that resource."],
          [ :not_acceptable, 406,"The requested resource is only capable of generating content not acceptable according to the Accept headers sent in the request."],
          [ :request_timeout, 408,"The server timed out waiting for the request."],
          [ :conflict, 409, "Indicates that the request could not be processed because of conflict in the request, such as an edit conflict in the case of multiple updates."],
          [ :precondition_failed, 412,"The server does not meet one of the preconditions that the requester put on the request."],
          [ :unprocessable_entity, 422,"The request was well-formed but was unable to be followed due to semantic errors."],
        ].each do |name, code, base_description|
          api.response_template name do |media_type: nil, location: nil, headers: nil, description: nil|
            status code
            description( description || base_description ) # description can "potentially" be overriden in an individual action.

            media_type media_type if media_type
            location location if location
            headers headers if headers
          end
        end

      end
      
      require 'praxis/responses/internal_server_error'
      self.api_definition.define do |api|
        api.response_template :internal_server_error do
          description "A generic error message, given when an unexpected condition was encountered and no more specific message is suitable."
          status 500
          media_type "application/json"
        end
      end
      
      require 'praxis/responses/validation_error'
      self.api_definition.define do |api|
        api.response_template :validation_error do
          description "An error message indicating that one or more elements of the request did not match the API specification for the action"
          status 400
          media_type "application/json"
        end
      end
      
      
      require 'praxis/responses/multipart_ok'
      self.api_definition.define do |api|
        api.response_template :multipart_ok do |media_type: Praxis::Types::MultipartArray|
          status 200
          media_type media_type
        end
      end
      
      builtin_handlers = {
        'plain' => Praxis::Handlers::Plain,
        'json' => Praxis::Handlers::JSON,
        'x-www-form-urlencoded' => Praxis::Handlers::WWWForm
      }
      
      # Register built-in handlers unless the app already provided its own
      builtin_handlers.each_pair do |name, handler|
        self.handler(name, handler) unless handlers.key?(name)
      end
      
      setup_initial_config!
      
      unless skip_registration
        if self.class.registered_apps[name]
          raise "A Praxis instance named #{name} has already been registered, please use the :name parameter to initialize them"
        end
        self.class.registered_apps[name] = self
      end
      $praxis_initializing_instance = old
    end

    def setup_initial_config!
      self.config do
        attribute :praxis do
          attribute :validate_responses, Attributor::Boolean, default: false
          attribute :validate_response_bodies, Attributor::Boolean, default: false

          attribute :show_exceptions, Attributor::Boolean, default: false
          attribute :x_cascade, Attributor::Boolean, default: true
        end
      end
    end


    def setup(root: '.')
      return self unless @app.nil?
      saved_value = $praxis_initializing_instance
      $praxis_initializing_instance = self
      @root = Pathname.new(root).expand_path

      bootloader.setup!
      builder.run(@router)
      @app = builder.to_app

      $praxis_initializing_instance = saved_value
      self
    end

    def middleware(middleware, *args, &block)
      @builder.use(middleware, *args, &block)
    end

    # Register a media type handler used to transform medias' structured data
    # to HTTP response entitites with a specific encoding (JSON, XML, etc)
    # and to parse request bodies into structured data.
    #
    # @param [String] name
    # @param [Class] a class that responds to .new, #parse and #generate

    def handler(name, handler)
      # Construct an instance, if the handler is a class and needs to be initialized.
      handler = handler.new

      # Make sure it quacks like a handler.
      unless handler.respond_to?(:generate) && handler.respond_to?(:parse)
        raise ArgumentError, "Media type handlers must respond to #generate and #parse"
      end

      # Register that thing!
      @handlers[name.to_s] = handler
    end

    def call(env)
      response = []
      old = Thread.current[:praxis_instance]
      Thread.current[:praxis_instance] = self
      Notifications.instrument 'rack.request.all'.freeze, response: response do
        response.push(*@app.call(env))
      end
    ensure
      Thread.current[:praxis_instance] = old      
    end

    def layout(&block)
      self.file_layout = FileGroup.new(self.root, &block)
    end

    def config(key=nil, type=Attributor::Struct, **opts, &block)
      if block_given? || (type==Attributor::Struct && !opts.empty? )
        @config.define(key, type, opts, &block)
      else
        @config.get
      end
    end

    def config=(config)
      @config.set(config)
    end

  end
end
