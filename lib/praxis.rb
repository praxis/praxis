require 'rack'
require 'attributor'
require 'praxis-blueprints'

require 'active_support/concern'
require 'praxis/request_superclassing'
require 'active_support/inflector'

$:.unshift File.dirname(__FILE__)

require 'mime'
module MIME
  class Header
    attr_reader :headers
  end
end

module Praxis

  autoload :ActionDefinition, 'praxis/action_definition'
  autoload :ApiGeneralInfo, 'praxis/api_general_info'
  autoload :ApiDefinition, 'praxis/api_definition'
  autoload :Application, 'praxis/application'
  autoload :Bootloader, 'praxis/bootloader'
  autoload :Config, 'praxis/config'
  autoload :Controller, 'praxis/controller'
  autoload :Callbacks, 'praxis/callbacks'
  autoload :Dispatcher, 'praxis/dispatcher'
  autoload :ErrorHandler, 'praxis/error_handler'
  autoload :ValidationHandler, 'praxis/validation_handler'
  autoload :Exception, 'praxis/exception'
  autoload :FileGroup,'praxis/file_group'
  autoload :Plugin, 'praxis/plugin'
  autoload :PluginConcern, 'praxis/plugin_concern'
  autoload :Request, 'praxis/request'
  autoload :ResourceDefinition, 'praxis/resource_definition'
  autoload :Response, 'praxis/response'
  autoload :ResponseDefinition, 'praxis/response_definition'
  autoload :ResponseTemplate, 'praxis/response_template'
  autoload :Route, 'praxis/route'
  autoload :Router, 'praxis/router'
  autoload :RoutingConfig, 'praxis/routing_config'
  autoload :SimpleMediaType, 'praxis/simple_media_type'
  autoload :Stage, 'praxis/stage'
  autoload :Trait, 'praxis/trait'

  autoload :Notifications, 'praxis/notifications'
  autoload :MiddlewareApp, 'praxis/middleware_app'

  autoload :RestfulDocGenerator, 'praxis/restful_doc_generator'
  module Docs
    autoload :Generator, 'praxis/docs/generator'
    autoload :LinkBuilder, 'praxis/docs/link_builder'
    autoload :OpenApiGenerator, 'praxis/docs/open_api_generator'
  end

  # types
  module Types
    autoload :FuzzyHash, 'praxis/types/fuzzy_hash'
    autoload :MediaTypeCommon, 'praxis/types/media_type_common'
    autoload :MultipartArray, 'praxis/types/multipart_array'
  end

  autoload :Links, 'praxis/links'
  autoload :MediaType, 'praxis/media_type'
  autoload :MediaTypeIdentifier, 'praxis/media_type_identifier'
  autoload :Multipart, 'praxis/types/multipart'
  autoload :Collection, 'praxis/collection'

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

  module Extensions
    autoload :MapperSelectors, 'praxis/extensions/mapper_selectors'
    autoload :Rendering, 'praxis/extensions/rendering'
    autoload :FieldExpansion, 'praxis/extensions/field_expansion'
    autoload :ActiveRecordFilterQueryBuilder, 'praxis/extensions/attribute_filtering/active_record_filter_query_builder'
    autoload :SequelFilterQueryBuilder, 'praxis/extensions/attribute_filtering/sequel_filter_query_builder'
  end

  module Handlers
    autoload :Plain, 'praxis/handlers/plain'
    autoload :JSON, 'praxis/handlers/json'
    autoload :WWWForm, 'praxis/handlers/www_form'
    autoload :XML, 'praxis/handlers/xml'
  end

  module BootloaderStages
    autoload :FileLoader, 'praxis/bootloader_stages/file_loader'
    autoload :Environment, 'praxis/bootloader_stages/environment'

    autoload :PluginLoader, 'praxis/bootloader_stages/plugin_loader'
    autoload :PluginConfigPrepare, 'praxis/bootloader_stages/plugin_config_prepare'
    autoload :PluginConfigLoad, 'praxis/bootloader_stages/plugin_config_load'
    autoload :PluginSetup, 'praxis/bootloader_stages/plugin_setup'

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

  module Mapper
    autoload :Resource, 'praxis/mapper/resource'
    autoload :SelectorGenerator, 'praxis/mapper/selector_generator'
  end

  # Avoid loading responses (and templates) lazily as they need to be registered in time
  require 'praxis/responses/http'
  require 'praxis/responses/internal_server_error'
  require 'praxis/responses/validation_error'
  require 'praxis/responses/multipart_ok'

end
