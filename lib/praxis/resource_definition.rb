require 'active_support/concern'
require 'active_support/inflector'


module Praxis
  module ResourceDefinition
    extend ActiveSupport::Concern

    included do
      @version = 'n/a'.freeze
      @actions = Hash.new
      @responses = Hash.new
      @action_defaults = []
      @version_options = {}
      @options = {}
      Application.instance.resource_definitions << self
    end

    module ClassMethods
      attr_reader :actions
      attr_reader :routing_config
      attr_reader :responses
      attr_reader :version_options
      attr_reader :options
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

      def action_defaults(&block)
        return @action_defaults unless block_given?

        @action_defaults << block
      end
  
      def params(type=Attributor::Struct, **opts, &block)
        warn 'DEPRECATION: ResourceDefinition.params is deprecated. Use it in action_defaults instead.'
        action_defaults do
          params type, **opts, &block
        end
      end      

      def payload(type=Attributor::Struct, **opts, &block)
        warn 'DEPRECATION: ResourceDefinition.payload is deprecated. Use action_defaults instead.'
        action_defaults do
          payload type, **opts, &block
        end
      end

      def headers(**opts, &block)
        warn 'DEPRECATION: ResourceDefinition.headers is deprecated. Use action_defaults instead.'
        action_defaults do
          headers **opts, &block
        end
      end
      
      def response(name, **args)
        warn 'DEPRECATION: ResourceDefinition.response is deprecated. Use action_defaults instead.'
        action_defaults do
          response name, **args
        end
      end

      def action(name, &block)
        raise ArgumentError, "can not create ActionDefinition without block" unless block_given?
        @actions[name] = ActionDefinition.new(name, self, &block)
      end

      def description(text=nil)
        @description = text if text
        @description
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

      def nodoc!
        options[:doc_visibility] = :nodoc
      end

    end

  end
end
