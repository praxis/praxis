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

          the_schema = if type.anonymous? || !(type < Praxis::MediaType) # Avoid referencing  custom/simple Types? (i.e., just MTs)
                         SchemaObject.new(info: type).dump_schema
                       else
                         { '$ref': "#/components/schemas/#{type.id}" }
                       end

          if example_payload
            examples_by_content_type = {}
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

          # Key string (of MT) , value MTObject
          content_hash = examples_by_content_type.each_with_object({}) do |(content_type, example_hash), accum|
            accum[content_type] = MediaTypeObject.new(
              schema: the_schema, # Every MT will have the same exact type..oh well .. maybe a REF?
              example: example_hash
            ).dump
          end
        end
      end
    end
  end
end
