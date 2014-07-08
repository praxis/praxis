module Praxis
  class MediaType < Taylor::Blueprint

    class DSLCompiler < Attributor::DSLCompiler
      def links(&block)
        attribute :links, Praxis::Links.for(options[:reference]), dsl_compiler: Links::DSLCompiler, &block
      end
    end

    def self.description(text=nil)
      @description = text if text
      @description
    end

    def self.identifier(identifier=nil)
      return @identifier unless identifier
      # TODO: parse the string and extract things like collection , and format type?...
      @identifier = identifier
    end

    def self.describe(shallow = false)
      super.merge!(identifier: @identifier, description: @description)
    end

    def self.attributes(opts={}, &block)
      super(opts.merge(dsl_compiler: MediaType::DSLCompiler), &block)
    end

    def links
      self.class::Links.new(@object)
    end


  end

end