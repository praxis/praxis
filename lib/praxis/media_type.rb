module Praxis
  # An Internet Media Type as defined in RFC 1590, as used in HTTP (see RFC 2616). As used in the
  # Praxis framework, media types also define the structure and content of entities of that type:
  # the attributes that exist, their names and types.
  #
  # An object with a media type can be represented on the wire using different structured-syntax
  # encodings; for example, a controller might respond with an actual Widget object, but a
  # Content-Type header specifying 'application/vnd.acme.widget+json'; Praxis uses the information
  # contained in the media-type definition of Widget to transform the object into an equivalent
  # JSON representation. If the content type ends with '+xml' instead, and the XML handler is
  # registered with the framework, Praxis will respond with an XML representation of the
  # widget. The use of media types allows your application's models to be decoupled from its
  # HTTP interface specification.
  #
  # A media type definition consists of:
  #   - a MIME type identifier
  #   - attributes, each of which has a name and a data type
  #   - named links to other resources
  #   - named views, which expose interesting subsets of attributes
  #
  # @example Declare a widget type that's used by my supply-chain management app
  #   class MyApp::MediaTypes::Widget < Praxis::MediaType
  #     description 'Represents a widget'
  #     identifier 'application/vnd.acme.widget'
  #
  #     attributes do
  #       attribute :id, Integer
  #         description: 'Database ID'
  #       attribute :href, Attributor::Href,
  #         description: 'Canonical resource refernece'
  #       attribute :color, String,
  #         example: 'red'
  #       attribute :material, String,
  #         description: 'Construction medium of the widget',
  #         values: ['copper', 'steel', 'aluminum']
  #       attribute :factory, MyApp::MediaTypes::Factory,
  #         description: 'The factory in which this widget was produced'
  #     end
  #
  #     links do
  #       link :factory,
  #         description: 'Link to the factory in which this widget was produced'
  #     end
  #
  #     # If widgets can be linked-to by other resources, they should have a link view
  #     view :link do
  #       attribute :href
  #     end
  #
  #     # All resources should have a default view
  #     view :default do
  #       attribute :id
  #       attribute :color
  #       attribute :material
  #     end
  #   end
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
