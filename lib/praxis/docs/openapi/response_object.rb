require_relative 'media_type_object'

module Praxis
  module Docs
    module OpenApi
      class ResponseObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#response-object
        attr_reader :info
        def initialize(info:)
          @info = info
          default_handlers = ApiDefinition.instance.info.produces
          @output_handlers = Praxis::Application.instance.handlers.select do |k,v|
            default_handlers.include?(k)
          end
        end

        def dump_response_headers_object( headers )
          headers.each_with_object({}) do |(name,data),accum|
            # data is a hash with :value and :type keys
            # How did we say in that must match a value in json schema again??
            binding.pry
            accum[name] = {
              schema: SchemaObject.new(info: data[:type])
              # allowed values:  [ data[:value] ] ??? is this the right json schema way?
            }
          end
        end

        def dump
          data = { 
            description: info.description || ''
          }
          if headers_object = dump_response_headers_object( info.headers )
            data[:headers] = headers_object
          end

          if info.media_type

            identifier = MediaTypeIdentifier.load(info.media_type.identifier)
            example_handlers = @output_handlers.each_with_object([]) do |(name, _handler), accum|
              accum.push({ (identifier + name).to_s => name})
            end
            data[:content] = MediaTypeObject.create_content_attribute_helper(
                                                                            type: info.media_type, 
                                                                            example_payload: info.example(nil),
                                                                            example_handlers: example_handlers)
          end

          # if payload = info[:payload]
          #   body_type= payload[:id]
          #   raise "WAIT! response payload doesn't have an existing id for the schema!!! (do an if, and describe it if so)" unless body_type
          #   data[:schema] = {"$ref" => "#/definitions/#{body_type}" }
          # end

          
          # TODO: we do not support 'links'
          data
        end

        
      end
    end
  end
end
