# frozen_string_literal: true

module Praxis
  class Blueprint
    class DSLCompiler < Attributor::HashDSLCompiler
      # group DSL is meant to group a subset of attributes in the media type (instead of presenting all things flat)
      # It will create a normal attribute, but as a BlueprintAttributeGroup, rather than a Struct, so that we can more easily
      # pass in objects that respond to the right methods, and avoid a Struct loading them all in hash keys.
      # For example, if there are computationally intensive attributes in the subset, we want to make sure those functions
      # aren't invoked by just merely loading, and only really invoked when we've asked to render them
      # It takes the name of the group, and passes the attributes block that needs to be a subset of the MediaType where the group resides
      def group(name, **options, &block)
        # Pass the reference to the target type by default. But allow overriding it if needed
        attribute(name, Praxis::BlueprintAttributeGroup.for(target), **{reference: target}.merge(options), &block)
      end
    end

    # Simple helper class that can parse the `attribute :foobar` dsl into
    # an equivalent structure hash. Example:
    # do
    #   attribute :one
    #   attribute :complex do
    #     attribute :sub1
    #   end
    #  end
    # is parsed as: { one: true, complex: { sub1: true} }
    class FieldsetParser
      def initialize(&block)
        @hash = nil
        @block = block
      end

      def attribute(name, **args, &block)
        unless args.empty?
          raise "Default fieldset definitions do not accept parameters (got: #{args})" \
                "If you're upgrading from a previous version of Praxis and still using the view :default " \
                "block syntax, make sure you don't use any view: X parameters when you define the attributes " \
                '(expand them explicitly if you want deeper structure)' \
                "The offending view with parameters is defined in:\n#{Kernel.caller.first}"
        end
        @hash[name] = block_given? ? FieldsetParser.new(&block).fieldset : true
      end

      def fieldset
        return @hash if @hash

        # Lazy eval
        @hash = {}
        instance_eval(&@block)
        @hash
      end
    end
    include Attributor::Type
    include Attributor::Container
    include Attributor::Dumpable

    extend Finalizable

    @@caching_enabled = false # rubocop:disable Style/ClassVars

    attr_reader :validating
    attr_accessor :object

    class << self
      attr_reader :attribute, :options
      # attr_accessor :reference
    end

    def self.inherited(klass)
      super

      klass.instance_eval do
        @options = {}
        @domain_model = Object
        @default_fieldset = {}
      end
    end

    # Override default new behavior to support memoized creation through an IdentityMap
    def self.new(object)
      # TODO: do we want to allow the identity map thing in the object?...maybe not.
      if @@caching_enabled
        return cache[object] ||= begin
          blueprint = allocate
          blueprint.send(:initialize, object)
          blueprint
        end
      end

      blueprint = allocate
      blueprint.send(:initialize, object)
      blueprint
    end

    def self.family
      'hash'
    end

    def self.attributes(opts = {}, &block)
      if block_given?
        raise 'Redefining Blueprint attributes is not currently supported' if const_defined?(:Struct, false)

        @options.merge!(opts.merge(dsl_compiler: DSLCompiler))
        @block = block

        return @attribute
      end

      raise "@attribute not defined yet for #{name}" unless @attribute

      @attribute.attributes
    end

    def self.domain_model(klass = nil)
      return @domain_model if klass.nil?

      @domain_model = klass
    end

    def self.check_option!(name, value)
      Attributor::Struct.check_option!(name, value)
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      case value
      when self
        value
      when nil, Hash, String
        if (value = attribute.load(value, context, **options))
          new(value)
        end
      else
        if value.is_a?(domain_model) || value.is_a?(self::Struct)
          # Wrap the value directly
          new(value)
        else
          # Wrap the object inside the domain_model
          new(domain_model.new(value))
        end
      end
    end

    class << self
      alias from load
    end

    def self.caching_enabled?
      @@caching_enabled
    end

    def self.caching_enabled=(caching_enabled)
      @@caching_enabled = caching_enabled # rubocop:disable Style/ClassVars
    end

    # Fetch current blueprint cache, scoped by this class
    def self.cache
      Thread.current[:praxis_blueprints_cache][self]
    end

    def self.cache=(cache)
      Thread.current[:praxis_blueprints_cache] = cache
    end

    def self.valid_type?(value)
      value.is_a?(self) || value.is_a?(attribute.type)
    end

    def self.example(context = nil, **values)
      context = case context
                when nil
                  ["#{name}-#{values.object_id}"]
                when ::String
                  [context]
                else
                  context
                end

      new(attribute.example(context, values: values))
    end

    def self.validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
      raise ArgumentError, "Invalid context received (nil) while validating value of type #{name}" if context.nil?

      context = [context] if context.is_a? ::String

      raise ArgumentError, "Error validating #{Attributor.humanize_context(context)} as #{name} for an object of type #{value.class.name}." unless value.is_a?(self)

      value.validate(context)
    end

    def self.default_fieldset(&block)
      return @default_fieldset unless block_given?

      @block_for_default_fieldset = block
    end

    def self.view(name, **_options, &block)
      unless name == :default
        raise "[ERROR] Views are no longer supported. Please use fully expanded fields when rendering.\n" \
              "NOTE that defining the :default view is deprecated, but still temporarily allowed, as an alias to define the default_fieldset.\n" \
              "A view for name #{name} is attempted to be defined in:\n#{Kernel.caller.first}"
      end
      raise 'Cannot define the default fieldset through the default view unless a block is passed' unless block_given?

      puts "[DEPRECATED] default fieldsets should be defined through `default_fieldset` instead of using the view :default block.\n" \
           "A default view is attempted to be defined in:\n#{Kernel.caller.first}"
      default_fieldset(&block)
    end

    def self.parse_default_fieldset(block)
      @default_fieldset = FieldsetParser.new(&block).fieldset
      @block_for_default_fieldset = nil
    end

    # renders using the implicit default fieldset
    def self.dump(object, context: Attributor::DEFAULT_ROOT_CONTEXT, **opts)
      object = self.load(object, context, **opts)
      return nil if object.nil?

      object.render(context: context, **opts)
    end

    class << self
      alias render dump
    end

    # Internal finalize! logic
    def self._finalize!
      if @block
        define_attribute!
        define_readers!
        # Don't blindly override a the default fieldset if the MediaType wants to define it on its own
        if @block_for_default_fieldset
          parse_default_fieldset(@block_for_default_fieldset)
        else
          generate_default_fieldset!
        end
        resolve_domain_model!
      end
      super
    end

    def self.resolve_domain_model!
      return unless domain_model.is_a?(String)

      @domain_model = domain_model.constantize
    end

    def self.define_attribute!
      @attribute = Attributor::Attribute.new(Attributor::Struct, @options, &@block)
      @block = nil
      @attribute.type.anonymous_type true
      const_set(:Struct, @attribute.type)
    end

    def self.define_readers!
      attributes.each do |name, _attribute|
        name = name.to_sym

        # Don't redefine existing methods
        next if instance_methods.include? name

        define_reader! name
      end
    end

    def self.define_reader!(name)
      attribute = attributes[name]
      # TODO: profile and optimize
      # because we use the attribute in the reader,
      # it's likely faster to use define_method here
      # than module_eval, but we should make sure.
      define_method(name) do
        value = @object.__send__(name)
        return value if value.nil? || value.is_a?(attribute.type)

        attribute.load(value)
      end
    end

    def self.generate_default_fieldset!
      attributes = self.attributes

      @default_fieldset = {}
      attributes.each do |name, attr|
        the_type = attr.type < Attributor::Collection ? attr.type.member_type : attr.type
        next if the_type < Blueprint
        # TODO: Allow groups in the default fieldset?? or perhaps better to make people explicitly define them?
        # next if (the_type < Blueprint && !(the_type < BlueprintAttributeGroup))

        # NOTE: we won't try to expand fields here, as we want to be lazy (and we're expanding)
        # every time a request comes in anyway. This could be an optimization we do at some point
        # or we can 'memoize it' to avoid trying to expand it over an over...
        @default_fieldset[name] = true
      end
    end

    def initialize(object)
      @object = object
      @validating = false
    end

    # By default we'll use the object identity, to avoid rendering the same object twice
    # Override, if there is a better way cache things up
    def _cache_key
      object
    end

    # Render the wrapped data with the given fields (or using the default fieldset otherwise)
    def render(fields: self.class.default_fieldset, context: Attributor::DEFAULT_ROOT_CONTEXT, renderer: Renderer.new, **_opts)
      # Accept a simple array of fields, and transform it to a 1-level hash with true values
      fields = fields.each_with_object({}) { |field, hash| hash[field] = true } if fields.is_a? Array

      renderer.render(self, fields, context: context)
    end

    alias dump render

    def to_h
      Attributor.recursive_to_h(@object)
    end

    def validate(context = Attributor::DEFAULT_ROOT_CONTEXT)
      raise ArgumentError, "Invalid context received (nil) while validating value of type #{name}" if context.nil?

      context = [context] if context.is_a? ::String

      raise 'validation conflict' if @validating

      @validating = true

      errors = []
      keys_provided = []

      keys_provided = object.contents.keys

      keys_provided.each do |key|
        sub_context = self.class.generate_subcontext(context, key)
        attribute = self.class.attributes[key]

        if object.contents[key].nil?
          errors.concat ["Attribute #{Attributor.humanize_context(sub_context)} is not nullable."] if !Attributor::Attribute.nullable_attribute?(attribute.options) && object.contents.key?(key) # It is only nullable if there's an explicite null: true (undefined defaults to false)
          # No need to validate the attribute further if the key wasn't passed...(or we would get nullable errors etc..cause the attribute has no
          # context if its containing key was even passed (and there might not be a containing key for a top level attribute anyways))
        else
          value = _get_attr(key)
          next if value.respond_to?(:validating) && value.validating # really, it's a thing with sub-attributes

          errors.concat attribute.validate(value, sub_context)
        end
      end

      leftover = self.class.attributes.keys - keys_provided
      leftover.each do |key|
        sub_context = self.class.generate_subcontext(context, key)
        attribute = self.class.attributes[key]

        errors.concat ["Attribute #{Attributor.humanize_context(sub_context)} is required."] if attribute.options[:required]
      end

      self.class.attribute.type.requirements.each do |requirement|
        validation_errors = requirement.validate(keys_provided, context)
        errors.concat(validation_errors) unless validation_errors.empty?
      end
      errors
    ensure
      @validating = false
    end

    # generic semi-private getter used by Renderer
    def _get_attr(name)
      send(name)
    end

    # Delegates the json-schema methods to the underlying attribute/member_type
    def self.as_json_schema(**args)
      @attribute.type.as_json_schema(args)
    end

    def self.json_schema_type
      @attribute.type.json_schema_type
    end
  end
end
