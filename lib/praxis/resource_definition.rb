require 'active_support/concern'
require 'active_support/inflector'

module Praxis
  module ResourceDefinition
    extend ActiveSupport::Concern
    DEFAULT_RESOURCE_HREF_ACTION = :show

    included do
      @version = 'n/a'.freeze
      @actions = Hash.new
      @responses = Hash.new
      @action_defaults = Trait.new
      @version_options = {}
      @metadata = {}
      @traits = []

      if self.name
        @routing_prefix = '/' + self.name.split("::").last.underscore
      else
        @routing_prefix = '/'
      end

      @version_prefix = ''

      Application.instance.resource_definitions << self
    end

    module ClassMethods
      attr_reader :actions
      attr_reader :responses
      attr_reader :version_options
      attr_reader :traits
      attr_reader :routing_prefix
      attr_reader :version_prefix
      # opaque hash of user-defined medata, used to decorate the definition,
      # and also available in the generated JSON documents
      attr_reader :metadata

      attr_accessor :controller

      # FIXME: this is inconsistent with the rest of the magic DSL convention.
      def routing(&block)
        warn "DEPRECATED: ResourceDefinition.routing is deprecated use prefix directly instead."

        # eval this assuming it will only call #prefix
        self.instance_eval(&block)
      end

      def prefix(prefix=nil)
        unless prefix.nil?
          @routing_prefix = prefix
        end
        @routing_prefix
      end

      def media_type(media_type=nil)
        return @media_type unless media_type

        if media_type.kind_of?(String)
          media_type = SimpleMediaType.new(media_type)
        end
        @media_type = media_type
      end

      def version(version=nil, options=nil)
        return @version unless version
        @version = version
        @version_options = options || {using: [:header,:params]}

        if @version_options
          version_using = Array(@version_options[:using])
          if version_using.include?(:path)
            @version_prefix = "#{Praxis::Request::path_version_prefix}#{self.version}"
          end
        end
      end

      def canonical_path( action_name=nil )
        if action_name
          raise "Canonical path for #{self.name} is already defined as: '#{@canonical_action_name}'. 'canonical_path' can only be defined once." if @canonical_action_name
          @canonical_action_name = action_name
        else
          # Resolution of the actual action definition needs to be done lazily, since we can use the `canonical_path` stanza
          # at the top of the resource, well before the actual action is defined.
          unless @canonical_action
            href_action = @canonical_action_name || DEFAULT_RESOURCE_HREF_ACTION
            @canonical_action = actions.fetch(href_action) do
              raise "Error: trying to set canonical_href of #{self.name}. Action '#{href_action}' does not exist"
            end
          end
          return @canonical_action
        end
      end

      def to_href( params )
        canonical_path.primary_route.path.expand(params)
      end

      def parse_href(path)
        param_values = canonical_path.primary_route.path.params(path)
        attrs = canonical_path.params.attributes
        param_values.each_with_object({}) do |(key,value),hash|
          hash[key.to_sym] = attrs[key.to_sym].load(value,[key])
        end
      rescue => e
        raise Praxis::Exception.new("Error parsing or coercing parameters from href: #{path}\n"+e.message)
      end

      def trait(trait_name)
        unless ApiDefinition.instance.traits.has_key? trait_name
          raise Exceptions::InvalidTrait.new("Trait #{trait_name} not found in the system")
        end
        trait = ApiDefinition.instance.traits.fetch(trait_name)
        @traits << trait_name
      end
      alias_method :use, :trait

      def action_defaults(&block)
        if block_given?
          @action_defaults.instance_eval(&block)
        end

        @action_defaults
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
        raise ArgumentError, "Action names must be defined using symbols (Got: #{name} (of type #{name.class}))" unless name.is_a? Symbol
        @actions[name] = ActionDefinition.new(name, self, &block)
      end

      def description(text=nil)
        @description = text if text
        @description
      end

      def id
        self.name.gsub('::'.freeze,'-'.freeze)
      end

      def describe
        {}.tap do |hash|
          hash[:description] = description
          hash[:media_type] = media_type.id if media_type
          hash[:actions] = actions.values.map(&:describe)
          hash[:name] = self.name
          hash[:metadata] = metadata
          hash[:traits] = self.traits
        end
      end

      def nodoc!
        metadata[:doc_visibility] = :none
      end

    end

  end
end
