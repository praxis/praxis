# frozen_string_literal: true

module Praxis
  module Docs
    module OpenApi
      class MediaTypeObject
        attr_reader :schema, :example

        def initialize(schema:, example:)
          @schema = schema
          @example = example
        end

        def dump
          {
            schema: schema,
            example: example
            # encoding: TODO SUPPORT IT maybe be great/necessary for multipart
          }
        end

        # Helper to create the typical content attribute for responses and request bodies
        def self.create_content_attribute_helper(type:, example_payload:, example_handlers: nil)
          # Will produce 1 example encoded with a given handler (and marking it with the given content type)
          example_handlers ||= [{ 'application/json' => 'json' }]
          # NOTE2: we should just create a $ref here unless it's an anon mediatype...
          return {} if type.is_a? SimpleMediaType # NOTE: skip if it's a SimpleMediaType?? ... is that correct?

          the_schema = if type.anonymous? || !(type < Praxis::MediaType)
                         # Avoid referencing custom/simple types (i.e. just MTs). As a corner case,
                         # dig into collections (which are anonymous) provided their member is not.
                         # This isn't germane to content attributes, but is necessary to ensure that we visit every
                         # non-anonymous type so that our emitted scheme covers the whole "surface area" of all
                         # actions.
                         underlying_type = type
                         underlying_type = underlying_type.member_type while underlying_type < Attributor::Collection

                         SchemaObject.new(info: type).dump_schema(
                           shallow: false,
                           allow_ref: type < Attributor::Collection && !underlying_type.anonymous?
                         )
                       else
                         SchemaObject.new(info: type).dump_schema(shallow: true, allow_ref: true)
                       end

          if example_payload
            examples_by_content_type = {}
            # We don't need to provide top-level examples for a multipart payload...each part
            # will provide its own example (and assembling a proper structured example for the whole
            # body isn't necessarily trivial based on the spec)
            # If we need to, someday, we can create the rendered_paylod by calling MultipartArray.self.dump_for_openapi
            # and properly complete that code to generate the appropriate thing, including the encoding etc...
            unless type < Praxis::Types::MultipartArray
              rendered_payload = example_payload.dump

              example_handlers.each do |spec|
                content_type, handler_name = spec.first
                handler = Praxis::Application.instance.handlers[handler_name]
                # ReDoc is not happy to display json generated outputs when served as JSON...wtf?
                generated = handler.generate(rendered_payload)
                final = handler_name == 'json' ? JSON.parse(generated) : generated
                examples_by_content_type[content_type] = final
              end
            end
          end

          # Key string (of MT) , value MTObject
          examples_by_content_type.transform_values do |example_hash|
            MediaTypeObject.new(
              schema: the_schema, # Every MT will have the same exact type..oh well .. maybe a REF?
              example: example_hash
            ).dump
          end
        end
      end
    end
  end
end
