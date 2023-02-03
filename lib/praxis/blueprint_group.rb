# frozen_string_literal: true

module Praxis
  class BlueprintGroup < Blueprint
    def self.constructable?
      true
    end
    # Construct a new subclass, using attribute_definition to define attributes.
    def self.construct(attribute_definition, options = {})
      # if we're in a subclass of Struct, but not attribute_definition is provided, we're
      # not REALLY trying to define a new struct. more than likely Collection is calling
      # construct on us.
      # unless self == Attributor::Struct || attribute_definition.nil?
      #   raise AttributorException, 'can not construct from already-constructed Struct'
      # end

      # TODO: massage the options here to pull out only the relevant ones

      # simply return Struct if we don't specify any sub-attributes....
      return self if attribute_definition.nil?

      # if options[:reference]
      #   options.merge!(options[:reference].options) do |_key, oldval, _newval|
      #     oldval
      #   end
      # end

      reference_type = @media_type
      # Construct a group-derived class with the given mediatype as the reference
      ::Class.new(self) do
        @reference  = reference_type
        attributes(**options, &attribute_definition)
      end
    end

    def self.for(media_type)
      return media_type::AttributeGrouping if defined?(media_type::AttributeGrouping) # Cache the grouping class

      ::Class.new(self) do
        @media_type = media_type
      end
    end

    # def self.inherited(klass)
    #   super
    # end

    # Override default new behavior to support memoized creation through an IdentityMap
    # def self.new(object)
    #   # # TODO: do we want to allow the identity map thing in the object?...maybe not.
    #   # if @@caching_enabled
    #   #   return cache[object] ||= begin
    #   #     blueprint = allocate
    #   #     blueprint.send(:initialize, object)
    #   #     blueprint
    #   #   end
    #   # end
    #   blueprint = allocate
    #   blueprint.send(:initialize, object)
    #   blueprint
    # end

    # def self.family
    #   'hash'
    # end

    # def self.attributes(opts = {}, &block)
    #   # Add the special self sauce here?
    #   super
    # end

    # def self.check_option!(name, value)
    #   # ???
    #   Attributor::Struct.check_option!(name, value)
    # end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      super
      # case value
      # when self
      #   value
      # when nil, Hash, String
      #   if (value = attribute.load(value, context, **options))
      #     new(value)
      #   end
      # else
      #   if value.is_a?(domain_model) || value.is_a?(self::Struct)
      #     # Wrap the value directly
      #     new(value)
      #   else
      #     # Wrap the object inside the domain_model
      #     new(domain_model.new(value))
      #   end
      # end
    end

    # def self.validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
    #   raise ArgumentError, "Invalid context received (nil) while validating value of type #{name}" if context.nil?

    #   context = [context] if context.is_a? ::String

    #   raise ArgumentError, "Error validating #{Attributor.humanize_context(context)} as #{name} for an object of type #{value.class.name}." unless value.is_a?(self)

    #   value.validate(context)
    # end

    # Internal finalize! logic
    # def self._finalize!
    #   # TODO: define the 'attribute name' method and return self?
    #   super
    # end

    
    # def self.define_attribute!
    #   @attribute = Attributor::Attribute.new(Attributor::Struct, @options, &@block)
    #   @block = nil
    #   @attribute.type.anonymous_type true
    #   const_set(:Struct, @attribute.type)
    # end

    # def initialize(object)
    #   @object = object
    #   @validating = false
    # end

    # Render the wrapped data with the given fields (or using the default fieldset otherwise)
    def render(fields: self.class.default_fieldset, context: Attributor::DEFAULT_ROOT_CONTEXT, renderer: Renderer.new, **_opts)
      # # Accept a simple array of fields, and transform it to a 1-level hash with true values
      # fields = fields.each_with_object({}) { |field, hash| hash[field] = true } if fields.is_a? Array

      # renderer.render(self, fields, context: context)
    end

    # def validate(context = Attributor::DEFAULT_ROOT_CONTEXT)
    #   raise ArgumentError, "Invalid context received (nil) while validating value of type #{name}" if context.nil?

    #   context = [context] if context.is_a? ::String

    #   raise 'validation conflict' if @validating

    #   @validating = true

    #   errors = []
    #   keys_provided = []

    #   self.class.attributes.each do |key, attribute|
    #     sub_context = self.class.generate_subcontext(context, key)
    #     value = _get_attr(key)
    #     keys_provided << key if @object.key?(key)

    #     next if value.respond_to?(:validating) && value.validating # really, it's a thing with sub-attributes

    #     # Isn't this handled by the requirements validation? NO! we might want to combine
    #     errors.concat ["Attribute #{Attributor.humanize_context(sub_context)} is required."] if attribute.options[:required] && !@object.key?(key)
    #     if @object[key].nil?
    #       errors.concat ["Attribute #{Attributor.humanize_context(sub_context)} is not nullable."] if !Attributor::Attribute.nullable_attribute?(attribute.options) && @object.key?(key) # It is only nullable if there's an explicite null: true (undefined defaults to false)
    #       # No need to validate the attribute further if the key wasn't passed...(or we would get nullable errors etc..cause the attribute has no
    #       # context if its containing key was even passed (and there might not be a containing key for a top level attribute anyways))
    #     else
    #       errors.concat attribute.validate(value, sub_context)
    #     end
    #   end
    #   self.class.attribute.type.requirements.each do |requirement|
    #     validation_errors = requirement.validate(keys_provided, context)
    #     errors.concat(validation_errors) unless validation_errors.empty?
    #   end
    #   errors
    # ensure
    #   @validating = false
    # end
  end
end
