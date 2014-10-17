module Praxis

  # Container for links for a given type
  class Links < Praxis::Blueprint

    class DSLCompiler < Attributor::DSLCompiler
      attr_reader :links
      def initialize(target, dsl_compiler_options:{}, **options)
        @links = dsl_compiler_options[:links]

        super
      end

      def link(name, type=nil, using: name, **opts, &block)
        links[name] = using
        attribute(name, type, **opts, &block)
      end
    end

    class << self
      attr_reader :links
    end

    def self.for(reference)
      if defined?(reference::Links)
        return reference::Links
      end

      klass = Class.new(self) do
        @reference = reference
        @links = Hash.new
      end

      reference.const_set :Links, klass
    end

    def self.construct(constructor_block, options)
      options[:reference] = @reference
      options[:dsl_compiler_options] = {links: self.links}

      self.attributes(options, &constructor_block)
      self
    end

    def self.describe(shallow=false)
      super(false) # Links must always describe attributes
    end
    
    def self._finalize!
      super
      if @attribute
        self.define_default_view
        self.fixup_reference_struct_methods
      end
    end

    def self.define_blueprint_reader!(name)
      # it's faster to use define_method in this case than module_eval
      # because we save the attribute lookup on every access.
      attribute = self.attributes[name]
      using = self.links.fetch(name) do
        raise Exceptions::InvalidConfiguration.new("Cannot define attribute for #{name.inspect}")
      end

      define_method(name) do
        value = @object.__send__(using)
        return value if value.nil? || value.kind_of?(attribute.type)
        attribute.type.new(value)
      end

      # do whatever crazy aliasing we need to here....
      unless name == using
        @attribute.type.instance_eval do
          define_method(using) do
            self.__send__(name)
          end
        end

        @reference.attribute.type.instance_eval do
          define_method(using) do
            self.__send__(name)
          end
        end
      end

    end

    def self.define_default_view
      return unless view(:default).nil?

      view(:default) {}
      self.attributes.each do |name, attribute|
        view(:default).attribute(name, view: :link)
      end
    end

    # Define methods on the inner Struct class for
    # links that do not have corresponding top-level attributes.
    # This is primarily necessary only for example generation.
    def self.fixup_reference_struct_methods
      self.links.each do |name, using|
        next if @reference.attribute.attributes.has_key?(name)
        @reference.attribute.type.instance_eval do
          define_method(using) do
            return nil unless attributes[:links]
            attributes[:links].__send__(name)
          end
        end
      end
    end

    def self.validate(*args)
      # FIXME: what to validate for links?
      []
    end

  end

end
