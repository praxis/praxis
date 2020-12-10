# frozen_string_literal: true

module Praxis
  class Blueprint    
    
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
      def initialize( &block)
        @hash = nil
        @block = block
      end
    
      def attribute(name, **args, &block)
        raise "Default fieldset definitions do not accept parameters (got: #{args})" \
              "If you're upgrading from a previous version of Praxis and still using the view :default " \
              "block syntax, make sure you don't use any view: X parameters when you define the attributes " \
              "(expand them explicitly if you want deeper structure)" \
              "The offending view with parameters is defined in:\n#{Kernel.caller.first}" unless args.empty?
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
    include Attributor::Dumpable

    extend Finalizable

    @@caching_enabled = false

    attr_reader :validating
    attr_accessor :object

    class << self
      attr_reader :attribute
      attr_reader :options
      attr_accessor :reference
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
        return self.cache[object] ||= begin
          blueprint = self.allocate
          blueprint.send(:initialize, object)
          blueprint
        end
      end

      blueprint = self.allocate
      blueprint.send(:initialize, object)
      blueprint
    end

    def self.family
      'hash'
    end

    def self.attributes(opts = {}, &block)
      if block_given?
        raise 'Redefining Blueprint attributes is not currently supported' if self.const_defined?(:Struct, false)

        if opts.key?(:reference) && opts[:reference] != self.reference
          raise "Reference mismatch in #{self.inspect}. Given :reference option #{opts[:reference].inspect}, while using #{self.reference.inspect}"
        elsif self.reference
          opts[:reference] = self.reference # pass the reference Class down
        else
          opts[:reference] = self
        end

        @options.merge!(opts)
        @block = block

        return @attribute
      end

      raise "@attribute not defined yet for #{self.name}" unless @attribute

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
        if (value = self.attribute.load(value, context, **options))
          self.new(value)
        end
      else
        if value.is_a?(self.domain_model) || value.is_a?(self::Struct)
          # Wrap the value directly
          self.new(value)
        else
          # Wrap the object inside the domain_model
          self.new(domain_model.new(value))
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
      @@caching_enabled = caching_enabled
    end

    # Fetch current blueprint cache, scoped by this class
    def self.cache
      Thread.current[:praxis_blueprints_cache][self]
    end

    def self.cache=(cache)
      Thread.current[:praxis_blueprints_cache] = cache
    end

    def self.valid_type?(value)
      value.is_a?(self) || value.is_a?(self.attribute.type)
    end

    def self.example(context = nil, **values)
      context = case context
                when nil
                  ["#{self.name}-#{values.object_id}"]
                when ::String
                  [context]
                else
                  context
                end

      self.new(self.attribute.example(context, values: values))
    end

    def self.validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
      raise ArgumentError, "Invalid context received (nil) while validating value of type #{self.name}" if context.nil?
      context = [context] if context.is_a? ::String

      unless value.is_a?(self)
        raise ArgumentError, "Error validating #{Attributor.humanize_context(context)} as #{self.name} for an object of type #{value.class.name}."
      end

      value.validate(context)
    end

    def self.default_fieldset(&block)
      return @default_fieldset unless block_given?

      @block_for_default_fieldset = block
    end

    def self.view(name, **options, &block)
      unless name == :default
        raise "[ERROR] Views are no longer supported. Please use fully expanded fields when rendering.\n" \
              "NOTE that defining the :default view is deprecated, but still temporarily allowed, as an alias to define the default_fieldset.\n" \
              "A view for name #{name} is attempted to be defined in:\n#{Kernel.caller.first}"
      end
      raise "Cannot define the default fieldset through the default view unless a block is passed" unless block_given?
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
        self.define_attribute!
        self.define_readers!
        # Don't blindly override a the default fieldset if the MediaType wants to define it on its own
        if @block_for_default_fieldset
          parse_default_fieldset(@block_for_default_fieldset) 
        else
          self.generate_default_fieldset!
        end
        self.resolve_domain_model!
      end
      super
    end

    def self.resolve_domain_model!
      return unless self.domain_model.is_a?(String)

      @domain_model = self.domain_model.constantize
    end

    def self.define_attribute!
      @attribute = Attributor::Attribute.new(Attributor::Struct, @options, &@block)
      @block = nil
      @attribute.type.anonymous_type true
      self.const_set(:Struct, @attribute.type)
    end

    def self.define_readers!
      self.attributes.each do |name, _attribute|
        name = name.to_sym

        # Don't redefine existing methods
        next if self.instance_methods.include? name

        define_reader! name
      end
    end

    def self.define_reader!(name)
      attribute = self.attributes[name]
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
        the_type = (attr.type < Attributor::Collection) ? attr.type.member_type : attr.type
        next if the_type < Blueprint
        # Note: we won't try to expand fields here, as we want to be lazy (and we're expanding)
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
      self.object
    end

    # Render the wrapped data with the given fields (or using the default fieldset otherwise)
    def render(fields: self.class.default_fieldset, context: Attributor::DEFAULT_ROOT_CONTEXT, renderer: Renderer.new, **opts)

      # Accept a simple array of fields, and transform it to a 1-level hash with true values
      if fields.is_a? Array
        fields = fields.each_with_object({}) { |field, hash| hash[field] = true }
      end

      expanded  = Praxis::FieldExpander.new.expand(self, fields)
      renderer.render(self, fields, context: context)
    end

    alias dump render

    def to_h
      Attributor.recursive_to_h(@object)
    end

    def validate(context = Attributor::DEFAULT_ROOT_CONTEXT)
      raise ArgumentError, "Invalid context received (nil) while validating value of type #{self.name}" if context.nil?
      context = [context] if context.is_a? ::String
      keys_with_values = []

      raise 'validation conflict' if @validating
      @validating = true

      errors = []
      self.class.attributes.each do |sub_attribute_name, sub_attribute|
        sub_context = self.class.generate_subcontext(context, sub_attribute_name)
        value = self.send(sub_attribute_name)
        keys_with_values << sub_attribute_name unless value.nil?

        if value.respond_to?(:validating) # really, it's a thing with sub-attributes
          next if value.validating
        end
        errors.concat(sub_attribute.validate(value, sub_context))
      end
      self.class.attribute.type.requirements.each do |req|
        validation_errors = req.validate(keys_with_values, context)
        errors.concat(validation_errors) unless validation_errors.empty?
      end
      errors
    ensure
      @validating = false
    end

    # generic semi-private getter used by Renderer
    def _get_attr(name)
      self.send(name)
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
