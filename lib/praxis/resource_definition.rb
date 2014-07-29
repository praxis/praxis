require 'active_support/concern'
require 'active_support/inflector'



module Praxis
  module ResourceDefinition
    extend ActiveSupport::Concern

    included do
      @version = 'n/a'.freeze
      @actions = Hash.new
      @responses = Hash.new
      @response_groups = Set[:default] #response groups cannot override things?...Do we need them? perhaps..
      Application.instance.resource_definitions << self
    end

    module ClassMethods
      attr_reader :actions
      attr_reader :routing_config
      attr_reader :responses

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

      def version(version=nil)
        return @version unless version
        @version = version
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

# TODO: Do we need this? a list of them without overriding anything?! or not
#      def responses(*responses)
#        @responses.merge(responses)
#      end

      def response(name, **args, &block)
        @responses[name] = [args,block] #TODO: Block not used/needed
      end

      def response_groups(*response_groups)
        @response_groups.merge(response_groups)
      end

      def describe
        {}.tap do |hash|
          hash[:description] = description
          hash[:media_type] = media_type.name if media_type
          hash[:actions] = actions.values.map(&:describe)
        end
      end

      def use(trait_name)
        raise "Trait #{trait_name} not found in the system" unless ApiDefinition.instance.traits.has_key? trait_name
        self.instance_eval(&ApiDefinition.instance.traits[trait_name])
      end

    end

  end
end
