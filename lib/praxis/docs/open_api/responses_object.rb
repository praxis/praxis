require_relative 'response_object'

module Praxis
  module Docs
    module OpenApi
      class ResponsesObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#responses-object
        attr_reader :responses
        def initialize(responses:)
          @responses = responses
        end


        def dump
          # {
          #   "200": {
          #     "description": "a pet to be returned",
          #     "content": {
          #       "application/json": {
          #         "schema": {
          #           type: :object
          #         }
          #       }
          #     }
          #   },
          #   "default": {
          #     "description": "Unexpected error",
          #     "content": {
          #       "application/json": {
          #         "schema": {
          #           type: :object
          #         }
          #       }
          #     }
          #   }
          # }
          responses.each_with_object({}) do |(_response_name, response_definition), hash|
            hash[response_definition.status.to_s] = ResponseObject.new(info: response_definition).dump
          end
        end
      end
    end
  end
end
