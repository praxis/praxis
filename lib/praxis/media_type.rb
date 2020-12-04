module Praxis
  # An Internet Media Type as defined in RFC 1590, as used in HTTP (see RFC 2616). As used in the
  # Praxis framework, media types also define the structure and content of entities of that type:
  # the attributes that exist, their names and types.
  #
  # An object with a media type can be represented on the wire using different structured-syntax
  # encodings; for example, a controller might respond with an actual Widget object, but a
  # Content-Type header specifying 'application/vnd.acme.widget+json'; Praxis uses the information
  # contained in the media-type definition of Widget to transform the object into an equivalent
  # JSON representation. The use of media types allows your application's models to be decoupled from its
  # HTTP interface specification.
  #
  # A media type definition consists of:
  #   - a MIME type identifier
  #   - attributes, each of which has a name and a data type
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
  #     # All resources will be assigned a default_fieldset (with only non-blueprint attributes)
  #     # But one can explicitly tailor that by using the `default_fieldset` DSL
  #     default_fieldset do
  #       attribute :id
  #       attribute :color
  #       attribute :material
  #     end
  #   end
  class MediaType < Praxis::Blueprint

    include Types::MediaTypeCommon
  end

end
