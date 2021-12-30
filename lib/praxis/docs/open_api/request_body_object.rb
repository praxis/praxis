# frozen_string_literal: true
require_relative 'schema_object'

module Praxis
  module Docs
    module OpenApi
      class RequestBodyObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#request-body-object
        attr_reader :attribute

        def initialize(attribute:)
          @attribute = attribute
        end

        def dump
          h = {}
          h[:description] = attribute.options[:description] if attribute.options[:description]
          h[:required] = attribute.options[:required] || false

          # OpenApi wants a set of bodies per MediaType/Content-Type
          # For us there's really only one schema (regardless of encoding)...
          # so we'll show all the supported MTs...but repeating the schema
          # dumped_schema = SchemaObject.new(info: attribute).dump_schema

          example_handlers = if attribute.type < Praxis::Types::MultipartArray
                               ident = MediaTypeIdentifier.load('multipart/form-data')
                               [{ ident.to_s => 'plain' }] # Multipart content type, but with the plain renderer (so there's no modification)
                             else
                               # TODO: We could run it through other handlers I guess...if they're registered
                               [{ 'application/json' => 'json' }]
                             end

          h[:content] = MediaTypeObject.create_content_attribute_helper(type: attribute.type,
                                                                        example_payload: attribute.example(nil),
                                                                        example_handlers: example_handlers)
          # # Key string (of MT) , value MTObject
          # content_hash = info[:examples].each_with_object({}) do |(handler, example_hash),accum|
          #   content_type = example_hash[:content_type]
          #   accum[content_type] = MediaTypeObject.new(
          #     schema: dumped_schema, # Every MT will have the same exact type..oh well
          #     example: info[:examples][handler][:body],
          #   ).dump
          # end
          # # TODO! Handle Multipart types! they look like arrays now in the schema...etc
          # h[:content] = content_hash
          h
        end
      end
    end
  end
end
