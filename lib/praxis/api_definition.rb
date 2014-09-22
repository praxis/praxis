require 'singleton'
require 'forwardable'

module Praxis

  class ApiDefinition
    include Singleton
    extend Forwardable

    attr_reader :traits
    attr_reader :responses

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
      self.traits[name] = block
    end


    define do |api|
      api.response_template :ok do |media_type: |
        media_type media_type
        status 200
      end

      api.response_template :created do |location: nil|
        location location
        status 201
      end
    end

  end

end
