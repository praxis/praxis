require 'singleton'
require 'forwardable'

module Praxis

  class ApiDefinition
#    include Singleton
    extend Forwardable

    attr_reader :traits
    attr_reader :responses
    attr_reader :infos
    attr_reader :global_info

    attr_accessor :versioning_scheme

    def self.instance
      i = Thread.current[:praxis_instance] || $praxis_initializing_instance
      raise "Trying to use Praxis::ApiDefinition outside the context of a Praxis::Application" unless i
      i.api_definition
    end
    
    def self.define(&block)
      
      definition = Praxis::Application.instance.api_definition
      if block.arity == 0
        definition.instance_eval(&block)
      else
        yield(definition)
      end
    end
    
    def define(&block)
      if block.arity == 0
        self.instance_eval(&block)
      else
        yield(self)
      end
    end

    def initialize
      @responses = Hash.new
      @traits = Hash.new
      @base_path = ''

      @global_info = ApiGeneralInfo.new

      @infos = Hash.new do |hash, version|
        hash[version] = ApiGeneralInfo.new(@global_info, version: version)
      end
    end

    def response_template(name, &block)
      @responses[name] = Praxis::ResponseTemplate.new(name, &block)
    end

    def response(name)
      return @responses.fetch(name) do
        raise ArgumentError, "no response template defined with name #{name.inspect}. Are you forgetting to register it with ApiDefinition?"
      end
    end

    def trait(name, &block)
      if self.traits.has_key? name
        raise Exceptions::InvalidTrait.new("Overwriting a previous trait with the same name (#{name})")
      end
      self.traits[name] = Trait.new(&block)
    end

    # Setting info to the nil version, means setting it for all versions (if they don't override them)
    def info(version=nil, &block)
      if version.nil?
        if block_given?
          @global_info.instance_eval(&block)
        else
          @global_info
        end
      else
        i = @infos[version]
        if block_given?
          i.instance_eval(&block)
        end
        i
      end
    end

    def describe
      data = Hash.new do |hash, version|
        hash[version] = Hash.new
      end

      data[:global][:info] = @global_info.describe

      # Fill in the "info" portion
      @infos.each do |version,info|
        data[version][:info] = info.describe
      end


      if traits.any?
        data[:traits] = {}
        traits.each do |name, trait|
          data[:traits][name] = trait.describe
        end
      end

      data
    end

    # CANNOT DEFINE IT AT FILE LOADING TIME: THE INSTANCE FOR THE API_DEFINITION IS NOT READY YET.
    # define do |api|
    #   api.response_template :ok do |media_type: , location: nil, headers: nil, description: nil |
    #     status 200
    #     description( description || 'Standard response for successful HTTP requests.' )
    #
    #     media_type media_type
    #     location location
    #     headers headers if headers
    #   end
    #
    #   api.response_template :created do |media_type: nil, location: nil, headers: nil, description: nil|
    #     status 201
    #     description( description || 'The request has been fulfilled and resulted in a new resource being created.' )
    #
    #     media_type media_type if media_type
    #     location location
    #     headers headers if headers
    #   end
    # end

  end

end
