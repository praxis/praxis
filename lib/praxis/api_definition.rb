require 'singleton'
require 'forwardable'

module Praxis

  class ApiDefinition
    include Singleton
    extend Forwardable

    attr_reader :traits
    attr_reader :responses
    attr_reader :infos
    attr_reader :global_info

    def self.define(&block)
      if block.arity == 0
        self.instance.instance_eval(&block)
      else
        yield(self.instance)
      end
    end

    def initialize
      @responses = Hash.new
      @traits = Hash.new
      @base_path = ''

      @global_info = ApiGeneralInfo.new

      @infos = Hash.new do |hash, version|
        hash[version] = ApiGeneralInfo.new(@global_info)
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

    define do |api|
      api.response_template :ok do |media_type: |
        media_type media_type
        status 200
        description 'Standard response for successful HTTP requests.'
      end

      api.response_template :created do |location: nil|
        location location
        status 201
        description 'The request has been fulfilled and resulted in a new resource being created.'
      end
    end

  end

end
