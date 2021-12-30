# frozen_string_literal: true

require 'singleton'
require 'forwardable'

module Praxis
  class ApiDefinition
    include Singleton
    extend Forwardable

    attr_reader :traits, :responses, :infos, :global_info

    attr_accessor :versioning_scheme

    def self.define(&block)
      if block.arity == 0
        instance.instance_eval(&block)
      else
        yield(instance)
      end
    end

    def initialize
      @responses = {}
      @traits = {}
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
      @responses.fetch(name) do
        raise ArgumentError, "no response template defined with name #{name.inspect}. Are you forgetting to register it with ApiDefinition?"
      end
    end

    def trait(name, &block)
      raise Exceptions::InvalidTrait, "Overwriting a previous trait with the same name (#{name})" if traits.has_key? name

      traits[name] = Trait.new(&block)
    end

    # Setting info to the nil version, means setting it for all versions (if they don't override them)
    def info(version = nil, &block)
      if version.nil?
        if block_given?
          @global_info.instance_eval(&block)
        else
          @global_info
        end
      else
        i = @infos[version]
        i.instance_eval(&block) if block_given?
        i
      end
    end

    def describe
      data = Hash.new do |hash, version|
        hash[version] = {}
      end

      data[:global][:info] = @global_info.describe

      # Fill in the "info" portion
      @infos.each do |version, info|
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
      api.response_template :ok do |media_type:, location: nil, headers: nil, description: nil|
        status 200
        description(description || 'Standard response for successful HTTP requests.')

        media_type media_type
        location
        headers&.each do |(name, value)|
          header(name: name, value: value)
        end
      end

      api.response_template :created do |media_type: nil, location: nil, headers: nil, description: nil|
        status 201
        description(description || 'The request has been fulfilled and resulted in a new resource being created.')

        media_type media_type if media_type
        location
        headers&.each do |(name, value)|
          header(name: name, value: value)
        end
      end
    end
  end
end
