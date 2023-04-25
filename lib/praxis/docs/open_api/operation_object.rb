# frozen_string_literal: true

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
            # externalDocs: {}, # TODO/FIXME
            operationId: id,
            responses: ResponsesObject.new(responses: action.responses).dump
            # callbacks
            # deprecated: false
            # security: [{}]
            # servers: [{}]
          }

          # Handle versioning header/params for the action in a special way, by linking to the existing component
          # spec that will be generated globally
          api_info = ApiDefinition.instance.infos[action.endpoint_definition.version]
          if (version_with = api_info.version_with)
            all_parameters.push('$ref' => '#/components/parameters/ApiVersionHeader') if version_with.include?(:header)
            all_parameters.push('$ref' => '#/components/parameters/ApiVersionParam') if version_with.include?(:params)
          end

          h[:description] = action.description if action.description
          h[:tags] = all_tags.uniq unless all_tags.empty?
          h[:parameters] = all_parameters unless all_parameters.empty?
          h[:requestBody] = RequestBodyObject.new(attribute: action.payload).dump if action.payload
          h
        end
      end
    end
  end
end
