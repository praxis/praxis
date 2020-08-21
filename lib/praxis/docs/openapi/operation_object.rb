require_relative 'parameter_object'
require_relative 'request_body_object'
require_relative 'responses_object'

module Praxis
  module Docs
    module OpenApi
      class OperationObject
        # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#operation-object
        attr_reader :id, :url, :action, :tags
        def initialize(id:, url:, action:, tags:)
          @id = id
          @url = url
          @action = action
          @tags = tags
        end

        def dump
          all_parameters = ParameterObject.process_parameters(action)
          all_tags = tags + action.traits
          h = {
            summary: action.name.to_s,
            description: action.description,
            #externalDocs: {}, # TODO/FIXME
            operationId: id,
            responses: ResponsesObject.new(responses: action.responses).dump, 
            # callbacks
            # deprecated: false
            # security: [{}]
            # servers: [{}]
          }
          h[:tags] = all_tags.uniq unless all_tags.empty?
          h[:parameters] = all_parameters unless all_parameters.empty?
          h[:requestBody] = RequestBodyObject.new(attribute: action.payload ).dump if action.payload
          h
        end
      end
    end
  end
end
