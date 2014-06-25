require 'rack'

require 'attributor'


$:.unshift File.dirname(__FILE__)

module Attributor
  class DSLCompiler
    def use(name)
      raise "Trait #{name} not found in the system" unless Praxis::ApiDefinition.instance.traits.has_key? name
      self.instance_eval(&Praxis::ApiDefinition.instance.traits[name])
    end
  end
end

module Praxis
  autoload :Application, 'praxis/application'
  autoload :Controller, 'praxis/controller'
  autoload :Response, 'praxis/response'
  autoload :Request, 'praxis/request'
  autoload :Router, 'praxis/router'
  autoload :ApiDefinition, 'praxis/api_definition'
  autoload :Dispatcher, 'praxis/dispatcher'
  autoload :ResourceDefinition, 'praxis/resource_definition'

  autoload :Bootloader, 'praxis/bootloader'
  autoload :Plugin, 'praxis/plugin'
  autoload :FileGroup,'praxis/file_group'
  autoload :SimpleMediaType, 'praxis/simple_media_type'
  autoload :Stage,       'praxis/stage'

  module Responses
    autoload :Default, 'praxis/responses/default'
    autoload :NotFound, 'praxis/responses/not_found'
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
    autoload :ResponseDefinition, 'praxis/skeletor/response_definition'
    autoload :RestfulActionConfig, 'praxis/skeletor/restful_action_config'
    autoload :RestfulSinatraApplicationConfig, 'praxis/skeletor/restful_sinatra_application_config'
    autoload :RestfulRoutingConfig, 'praxis/skeletor/restful_routing_config'



  end
end
