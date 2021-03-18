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
            # each header comes from Praxis::ResponseDefinition 
            # the keys are the header names, and value can be:
            #  "true"  => means it only needs to exist
            #  String => which means that it has to fully match
            #  Regex  => which means it has to regexp match it

            # Get the schema from the type (defaulting to string in case the type doesn't have the as_json_schema defined)
            schema = data[:attribute].type.as_json_schema rescue { type: :string }
            hash = { description: data[:description] || '', schema: schema }
            # Note, our Headers in response definition are not full types...they're basically only 
            # strings, which can either match anything, match the exact word or match a regex
            # they don't even have a description...
            data_value = data[:value]
            if data_value.is_a? String
              hash[:pattern] = "^#{data_value}$" # Exact String match
            elsif data_value.is_a? Regexp
              sanitized_pattern = data_value.inspect[1..-2] #inspect returns enclosing '/' characters
              hash[:pattern] = sanitized_pattern
            end

            accum[name] = hash
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
