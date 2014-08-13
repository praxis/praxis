require 'rack'
require 'attributor'
require 'taylor'

$:.unshift File.dirname(__FILE__)

module Attributor
  class DSLCompiler
    def use(name)
      unless Praxis::ApiDefinition.instance.traits.has_key? name
        raise Exceptions::InvalidTraitException.new("Trait #{name} not found in the system")
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

  # types
  autoload :Links, 'praxis/links'
  autoload :MediaType, 'praxis/media_type'
  autoload :Multipart, 'praxis/types/multipart'

  autoload :MultipartParser, 'praxis/multipart/parser'
  autoload :MultipartPart, 'praxis/multipart/part'

  class ActionDefinition
    autoload :HeadersDSLCompiler, 'praxis/action_definition/headers_dsl_compiler'
  end

  module Exceptions
    autoload :ConfigException, 'praxis/exceptions/config_exception'
    autoload :ConfigLoadException, 'praxis/exceptions/config_load_exception'
    autoload :ConfigValidationException, 'praxis/exceptions/config_validation_exception'
    autoload :InvalidConfigurationException, 'praxis/exceptions/invalid_configuration_exception'
    autoload :InvalidTraitException, 'praxis/exceptions/invalid_trait_exception'
    autoload :InvalidResponseException, 'praxis/exceptions/invalid_response_exception'
    autoload :StageNotFoundException, 'praxis/exceptions/stage_not_found_exception'
    autoload :ValidationException, 'praxis/exceptions/validation_exception'
  end

  module Responses
    autoload :Ok, 'praxis/responses/http'
    autoload :Created, 'praxis/responses/http'
    autoload :Accepted, 'praxis/responses/http'
    autoload :NoContent, 'praxis/responses/http'
    autoload :MultipleChoices, 'praxis/responses/http'
    autoload :MovedPermanently, 'praxis/responses/http'
    autoload :Found, 'praxis/responses/http'
    autoload :SeeOther, 'praxis/responses/http'
    autoload :NotModified, 'praxis/responses/http'
    autoload :TemporaryRedirect, 'praxis/responses/http'
    autoload :BadRequest, 'praxis/responses/http'
    autoload :Unauthorized, 'praxis/responses/http'
    autoload :Forbidden, 'praxis/responses/http'
    autoload :NotFound, 'praxis/responses/http'
    autoload :MethodNotAllowed, 'praxis/responses/http'
    autoload :NotAcceptable, 'praxis/responses/http'
    autoload :Conflict, 'praxis/responses/http'
    autoload :PreconditionFailed, 'praxis/responses/http'
    autoload :UnprocessableEntity, 'praxis/responses/http'
    autoload :InternalServerError, 'praxis/responses/http'

    autoload :ValidationError, 'praxis/responses/validation_error'
  end

  module BootloaderStages
    autoload :FileLoader, 'praxis/bootloader_stages/file_loader'
    autoload :Environment, 'praxis/bootloader_stages/environment'
    autoload :AppLoader, 'praxis/bootloader_stages/app_loader'
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
