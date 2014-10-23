require 'active_support/concern'
require 'active_support/inflector'



module Praxis
  module ResourceDefinition
    extend ActiveSupport::Concern

    included do
      @version = 'n/a'.freeze
      @actions = Hash.new
      @responses = Hash.new
      Application.instance.resource_definitions << self
    end

    module ClassMethods
      attr_reader :actions
      attr_reader :routing_config
      attr_reader :responses
      attr_reader :version_options
      
      attr_accessor :controller

      # FIXME: this is inconsistent with the rest of the magic DSL convention.
      def routing(&block)
        @routing_config = block
      end

      def media_type(media_type=nil)
        return @media_type unless media_type

        if media_type.kind_of?(String)
          media_type = SimpleMediaType.new(media_type)
        end
        @media_type = media_type
      end

      def version(version=nil, options= { using: [:header,:params] }.freeze )
        return @version unless version
        @version = version
        @version_options = options
      end

      
      def action(name, &block)
        @actions[name] = ActionDefinition.new(name, self, &block)
      end

      def params(type=Attributor::Struct, **opts, &block)
        return @params if type == Attributor::Struct && !block
        @params = [type, opts, block]
      end

      def payload(type=Attributor::Struct, **opts, &block)
        return @payload if type == Attributor::Struct && !block
        @payload = [type, opts, block]
      end

      def headers(**opts, &block)
        return @headers unless block
        @headers = [opts, block]
      end

      def description(text=nil)
        @description = text if text
        @description
      end

      def response(name, **args)
        @responses[name] = args
      end

      def describe
        {}.tap do |hash|
          hash[:description] = description
          hash[:media_type] = media_type.name if media_type
          hash[:actions] = actions.values.map(&:describe)
        end
      end

      def use(trait_name)
        unless ApiDefinition.instance.traits.has_key? trait_name
          raise Exceptions::InvalidTrait.new("Trait #{trait_name} not found")
        end
        self.instance_eval(&ApiDefinition.instance.traits[trait_name])
      end

    end

  end
end
