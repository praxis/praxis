require 'rack'
require 'attributor'
require 'praxis-mapper'
require 'praxis-blueprints'

$:.unshift File.dirname(__FILE__)

module Attributor
  class DSLCompiler
    def use(name)
      unless Praxis::ApiDefinition.instance.traits.has_key? name
        raise Exceptions::InvalidTrait.new("Trait #{name} not found in the system")
      end
      self.instance_eval(&Praxis::ApiDefinition.instance.traits[name])
    end
  end
end

require 'mime'
module MIME
  class Header
    attr_reader :headers
  end
end

module Praxis
  autoload :ActionDefinition, 'praxis/action_definition'
  autoload :ApiDefinition, 'praxis/api_definition'
  autoload :Application, 'praxis/application'
  autoload :Bootloader, 'praxis/bootloader'
  autoload :Config, 'praxis/config'
  autoload :Controller, 'praxis/controller'
  autoload :Callbacks, 'praxis/callbacks'
  autoload :Dispatcher, 'praxis/dispatcher'
  autoload :Exception, 'praxis/exception'
  autoload :FileGroup,'praxis/file_group'
  autoload :Plugin, 'praxis/plugin'
  autoload :Request, 'praxis/request'
  autoload :ResourceDefinition, 'praxis/resource_definition'
  autoload :Response, 'praxis/response'
  autoload :ResponseDefinition, 'praxis/response_definition'
  autoload :ResponseTemplate, 'praxis/response_template'
  autoload :Route, 'praxis/route'
  autoload :Router, 'praxis/router'
  autoload :SimpleMediaType, 'praxis/simple_media_type'
  autoload :Stage, 'praxis/stage'
  autoload :ContentTypeParser, 'praxis/content_type_parser'

  # types
  autoload :Links, 'praxis/links'
  autoload :MediaType, 'praxis/media_type'
  autoload :MediaTypeCollection, 'praxis/media_type_collection'
  autoload :Multipart, 'praxis/types/multipart'
  autoload :Collection, 'praxis/types/collection'

  autoload :MultipartParser, 'praxis/multipart/parser'
  autoload :MultipartPart, 'praxis/multipart/part'

  class ActionDefinition
    autoload :HeadersDSLCompiler, 'praxis/action_definition/headers_dsl_compiler'
  end

  module Exceptions
    autoload :Config, 'praxis/exceptions/config'
    autoload :ConfigLoad, 'praxis/exceptions/config_load'
    autoload :ConfigValidation, 'praxis/exceptions/config_validation'
    autoload :InvalidConfiguration, 'praxis/exceptions/invalid_configuration'
    autoload :InvalidTrait, 'praxis/exceptions/invalid_trait'
    autoload :InvalidResponse, 'praxis/exceptions/invalid_response'
    autoload :StageNotFound, 'praxis/exceptions/stage_not_found'
    autoload :Validation, 'praxis/exceptions/validation'
  end

  # Avoid loading responses (and templates) lazily as they need to be registered in time
  require 'praxis/responses/http'
  require 'praxis/responses/internal_server_error'
  require 'praxis/responses/validation_error'

  module BootloaderStages
    autoload :FileLoader, 'praxis/bootloader_stages/file_loader'
    autoload :Environment, 'praxis/bootloader_stages/environment'
    autoload :SubgroupLoader, 'praxis/bootloader_stages/subgroup_loader'
    autoload :WarnUnloadedFiles, 'praxis/bootloader_stages/warn_unloaded_files'
    autoload :Routing, 'praxis/bootloader_stages/routing'
  end

  module RequestStages
    autoload :RequestStage, 'praxis/request_stages/request_stage'
    autoload :LoadRequest, 'praxis/request_stages/load_request'
    autoload :Validate, 'praxis/request_stages/validate'
    autoload :ValidateParamsAndHeaders, 'praxis/request_stages/validate_params_and_headers'
    autoload :ValidatePayload, 'praxis/request_stages/validate_payload'
    autoload :Action, 'praxis/request_stages/action'
    autoload :Response, 'praxis/request_stages/response'
  end

  module Skeletor
    autoload :RestfulRoutingConfig, 'praxis/skeletor/restful_routing_config'
  end
end
