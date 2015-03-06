module Praxis
  class MediaType < Praxis::Blueprint
    include Types::MediaTypeCommon

    class DSLCompiler < Attributor::DSLCompiler
      def links(&block)
        attribute :links, Praxis::Links.for(options[:reference]), dsl_compiler: Links::DSLCompiler, &block
      end
    end

    def self.attributes(opts={}, &block)
      super(opts.merge(dsl_compiler: MediaType::DSLCompiler), &block)
    end

    def self._finalize!
      super
      if @attribute && self.attributes.key?(:links) && self.attributes[:links].type < Praxis::Links
        # Only define out special links accessor if it was setup using the special DSL
        # (we might have an app defining an attribute called `links` on its own, in which
        # case we leave it be)
        module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def links
          self.class::Links.new(@object)
        end
        RUBY
      end
    end
    
  end

end
