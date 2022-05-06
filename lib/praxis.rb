# frozen_string_literal: true

require 'rack'
require 'attributor'

require 'active_support/concern'
require 'praxis/request_superclassing'
require 'active_support/inflector'

$LOAD_PATH.unshift File.dirname(__FILE__)

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
  autoload :FileGroup, 'praxis/file_group'
  autoload :Plugin, 'praxis/plugin'
  autoload :PluginConcern, 'praxis/plugin_concern'
  autoload :Request, 'praxis/request'
  autoload :ResourceDefinition, 'praxis/resource_definition' # Deprecated: this is to support an easier transition
  autoload :EndpointDefinition, 'praxis/endpoint_definition'
  autoload :Response, 'praxis/response'
  autoload :ResponseDefinition, 'praxis/response_definition'
  autoload :ResponseTemplate, 'praxis/response_template'
  autoload :Route, 'praxis/route'
  autoload :Router, 'praxis/router'
  autoload :RoutingConfig, 'praxis/routing_config'
  autoload :SimpleMediaType, 'praxis/simple_media_type'
  autoload :Stage, 'praxis/stage'
  autoload :Trait, 'praxis/trait'
  autoload :ConfigHash, 'praxis/config_hash'
  autoload :Finalizable, 'praxis/finalizable'

  # Sort of part of the old Blueprints gem...but they're really not scoped...
  autoload :Blueprint, 'praxis/blueprint'
  autoload :FieldExpander, 'praxis/field_expander'
  autoload :Renderer, 'praxis/renderer'

  autoload :Notifications, 'praxis/notifications'
  autoload :MiddlewareApp, 'praxis/middleware_app'

  autoload :RestfulDocGenerator, 'praxis/restful_doc_generator'
  module Docs
    autoload :Generator, 'praxis/docs/generator'
    autoload :OpenApiGenerator, 'praxis/docs/open_api_generator'
  end

  # types
  module Types
    autoload :FuzzyHash, 'praxis/types/fuzzy_hash'
    autoload :MediaTypeCommon, 'praxis/types/media_type_common'
    autoload :MultipartArray, 'praxis/types/multipart_array'
  end

  autoload :MediaType, 'praxis/media_type'
  autoload :MediaTypeIdentifier, 'praxis/media_type_identifier'
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
    autoload :AttributeFiltering, 'praxis/extensions/attribute_filtering'
    autoload :ActiveRecordFilterQueryBuilder, 'praxis/extensions/attribute_filtering/active_record_filter_query_builder'
    autoload :SequelFilterQueryBuilder, 'praxis/extensions/attribute_filtering/sequel_filter_query_builder'
    autoload :Pagination, 'praxis/extensions/pagination'
    module Pagination
      autoload :ActiveRecordPaginationHandler, 'praxis/extensions/pagination/active_record_pagination_handler'
      autoload :SequelPaginationHandler, 'praxis/extensions/pagination/sequel_pagination_handler'
    end
  end

  module Handlers
    autoload :Plain, 'praxis/handlers/plain'
    autoload :JSON, 'praxis/handlers/json'
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
    autoload :ResourceCallbacks, 'praxis/mapper/resource_callbacks'
    autoload :SelectorGenerator, 'praxis/mapper/selector_generator'
    autoload :ModelQueryProxy, 'praxis/mapper/model_query_proxy'
    autoload :QueryMethods, 'praxis/mapper/query_methods'
    autoload :TypedMethods, 'praxis/mapper/typed_methods'

  end

  # Avoid loading responses (and templates) lazily as they need to be registered in time
  require 'praxis/responses/http'
  require 'praxis/responses/internal_server_error'
  require 'praxis/responses/validation_error'
  require 'praxis/responses/multipart_ok'
end
