require 'singleton'
require 'forwardable'

module Praxis

  class ApiDefinition
    include Singleton
    extend Forwardable

    attr_reader :traits
    attr_reader :responses

    def self.define
      yield(self.instance)
    end

    def initialize
      @responses = Hash.new
      @traits = Hash.new
    end

    def register_response(name, &block)
      @responses[name] = Praxis::ResponseTemplate.new(name, &block)
    end

    def response(name)
      return @responses.fetch(name) do
        raise ArgumentError, "no response defined with name #{name.inspect}"
      end
    end

    def trait(name, &block)
      if self.traits.has_key? name
        raise Exceptions::InvalidTraitException.new("Overwriting a previous trait with the same name (#{name})")
      end
      self.traits[name] = block
    end


    define do |api|
      api.register_response :ok do |media_type: |
        media_type media_type
        status 200
      end

      api.register_response :created do |media_type: |
        media_type media_type
        status 201
      end
    end

  end

end
