module Praxis

  # Container for links for a given type
  class Links < Taylor::Blueprint

    class DSLCompiler < Attributor::DSLCompiler
      alias_method :link, :attribute
    end

    def self.for(reference)
      if defined?(reference::Links)
        return reference::Links
      end

      klass = Class.new(self) do
        @reference = reference
      end

      reference.const_set :Links, klass
    end

    def self.construct(constructor_block, options)
      options[:reference] = @reference
      self.attributes(options, &constructor_block)
      self
    end

    def self._finalize!
      super
      if @attribute
        self.define_default_view
        self.fixup_reference_struct_methods
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
      @attribute.attributes.each do |name, attribute|
        next if @reference.attribute.attributes.has_key?(name)
        @reference.attribute.type.instance_eval do
          define_method(name) do
            attributes[:links].send(name)
          end
        end
      end
    end

  end
end
