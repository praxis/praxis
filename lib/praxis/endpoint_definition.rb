# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/inflector'

module Praxis
  module EndpointDefinition
    extend ActiveSupport::Concern

    DEFAULT_RESOURCE_HREF_ACTION = :show

    included do
      @version = 'n/a'
      @actions = {}
      @responses = {}

      @action_defaults = Trait.new(&EndpointDefinition.generate_defaults_block)

      @version_options = {}
      @metadata = {}
      @traits = []

      @prefix = if name
                  "/#{name.split('::').last.underscore}"
                else
                  '/'
                end

      @version_prefix = ''

      @parent = nil
      @parent_prefix = ''

      @routing_prefix = nil

      @on_finalize = []

      Application.instance.endpoint_definitions << self
    end

    def self.generate_defaults_block(version: nil)
      # Ensure we inherit any base params defined in the API definition for the passed in version
      base_attributes = if (base_params = ApiDefinition.instance.info(version).base_params)
                          base_params.attributes
                        else
                          {}
                        end

      proc do
        unless base_attributes.empty?
          params do
            base_attributes.each do |base_name, base_attribute|
              attribute base_name, base_attribute.type, **base_attribute.options
            end
          end
        end
      end
    end

    def self.finalize!
      Application.instance.endpoint_definitions.each do |resource_definition|
        while (block = resource_definition.on_finalize.shift)
          block.call
        end
      end
    end

    module ClassMethods
      attr_reader :actions, :responses, :version_options, :traits, :version_prefix, :parent_prefix

      # opaque hash of user-defined medata, used to decorate the definition,
      # and also available in the generated JSON documents
      attr_reader :metadata

      attr_accessor :controller

      def display_name(string = nil)
        unless string
          return @display_name ||= name.split('::').last # Best guess at a display name?
        end

        @display_name = string
      end

      def on_finalize(&block)
        @on_finalize << proc(&block) if block_given?

        @on_finalize
      end

      def prefix(prefix = nil)
        return @prefix if prefix.nil?

        @routing_prefix = nil # reset routing_prefix
        @prefix = prefix
      end

      def media_type(media_type = nil)
        return @media_type if media_type.nil?

        media_type = SimpleMediaType.new(media_type) if media_type.is_a?(String)
        @media_type = media_type
      end

      def parent(parent = nil, **mapping)
        return @parent if parent.nil?

        @routing_prefix = nil # reset routing_prefix

        parent_action = parent.canonical_path
        parent_route = parent_action.route.path

        # if a mapping is passed, it *must* resolve any param name conflicts
        unless mapping.any?
          # assume last capture is the relevant one to replace
          # if not... then I quit.
          parent_param_name = parent_route.names.last

          # more assumptions about names
          parent_name = parent.name.demodulize.underscore.singularize

          # put it together to find what we should call this new param
          param = "#{parent_name}_#{parent_param_name}".to_sym
          mapping[parent_param_name.to_sym] = param
        end

        # complete the mapping and massage the route
        parent_route.names.collect(&:to_sym).each do |name|
          if mapping.key?(name)
            param = mapping[name]
            # FIXME: this won't handle URI Template type paths, ie '/{parent_id}'
            prefixed_path = parent_action.route.prefixed_path
            @parent_prefix = prefixed_path.gsub(/(:)(#{name})(\W+|$)/, "\\1#{param}\\3")
          else
            mapping[name] = name
          end
        end

        on_finalize do
          inherit_params_from_parent(parent_action, **mapping)
        end

        @parent = parent
      end

      def inherit_params_from_parent(parent_action, **mapping)
        actions.each do |_name, action|
          action.params do
            mapping.each do |parent_name, name|
              next if action.params&.attributes&.key?(name)

              parent_attribute = parent_action.params.attributes[parent_name]

              attribute name, parent_attribute.type, **parent_attribute.options
            end
          end
        end
      end

      attr_writer :routing_prefix

      def routing_prefix
        return @routing_prefix if @routing_prefix

        @routing_prefix = parent_prefix + prefix
      end

      def version(version = nil)
        return @version unless version

        @version = version
        @action_defaults.instance_eval(&EndpointDefinition.generate_defaults_block(version: version))
      end

      def canonical_path(action_name = nil)
        if action_name
          raise "Canonical path for #{name} is already defined as: '#{@canonical_action_name}'. 'canonical_path' can only be defined once." if @canonical_action_name

          @canonical_action_name = action_name
        else
          # Resolution of the actual action definition needs to be done lazily, since we can use the `canonical_path` stanza
          # at the top of the resource, well before the actual action is defined.
          unless @canonical_action
            href_action = @canonical_action_name || DEFAULT_RESOURCE_HREF_ACTION
            @canonical_action = actions.fetch(href_action) do
              raise "Error: trying to set canonical_href of #{name}. Action '#{href_action}' does not exist"
            end
          end
          @canonical_action
        end
      end

      def to_href(params)
        canonical_path.route.path.expand(params.transform_values(&:to_s))
      end

      def parse_href(path)
        path = path.path if path.is_a?(::URI::Generic)
        param_values = canonical_path.route.path.params(path)
        attrs = canonical_path.params.attributes
        param_values.each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = attrs[key.to_sym].load(value, [key])
        end
      rescue StandardError => e
        raise Praxis::Exception, "Error parsing or coercing parameters from href: #{path}\n" + e.message
      end

      def trait(trait_name)
        raise Exceptions::InvalidTrait, "Trait #{trait_name} not found in the system" unless ApiDefinition.instance.traits.key? trait_name

        # TODO: We're only storing the names here, should we store the actual traits in a hash?
        @traits << trait_name
      end
      alias use trait

      def action_defaults(&block)
        @action_defaults.instance_eval(&block) if block_given?

        @action_defaults
      end

      def action(name, &block)
        raise ArgumentError, 'can not create ActionDefinition without block' unless block_given?
        raise ArgumentError, "Action names must be defined using symbols (Got: #{name} (of type #{name.class}))" unless name.is_a? Symbol

        action = ActionDefinition.new(name, self, &block)
        if action.sister_post_action
          # Save the finalization of the twin POST actions once we've loaded the endpoint definition
          on_finalize do
            # Create the sister POST action with a payload matching the original params
            post_action = action.clone_action_as_post
            @actions[post_action.name] = post_action
          end
        end
        @actions[name] = action
      end

      def description(text = nil)
        @description = text if text
        @description
      end

      def id
        name.gsub('::', '-')
      end

      def describe(context: nil)
        {}.tap do |hash|
          hash[:description] = description
          hash[:media_type] = media_type.describe(true) if media_type
          hash[:actions] = actions.values.collect { |action| action.describe(context: context) }
          hash[:name] = name
          hash[:parent] = parent.id if parent
          hash[:display_name] = display_name
          hash[:metadata] = metadata
          hash[:traits] = traits
        end
      end

      def nodoc!
        metadata[:doc_visibility] = :none
      end
    end
  end
end
