require 'rack'

require 'attributor'


$:.unshift File.dirname(__FILE__)

module Praxis
  autoload :Application, 'praxis/application'
  autoload :Controller, 'praxis/controller'
  autoload :Response, 'praxis/response'
  autoload :Request, 'praxis/request'
  autoload :Router, 'praxis/router'
  autoload :ApiResource, 'praxis/api_resource'
  autoload :Dispatcher, 'praxis/dispatcher'
  autoload :ResourceDefinition, 'praxis/resource_definition'
  
  module Responses
    autoload :Default, 'praxis/responses/default'
    autoload :NotFound, 'praxis/responses/not_found'
  end

  module Skeletor
    autoload :ResponseDefinition, 'praxis/skeletor/response_definition'
    autoload :RestfulActionConfig, 'praxis/skeletor/restful_action_config'
    autoload :RestfulSinatraApplicationConfig, 'praxis/skeletor/restful_sinatra_application_config'
    autoload :RestfulRoutingConfig, 'praxis/skeletor/restful_routing_config'

    autoload :Bootloader, 'praxis/skeletor/bootloader'
    autoload :Plugin, 'praxis/skeletor/plugin'
    autoload :FileGroup,'praxis/skeletor/file_group'

    module BootloaderStages
      autoload :Stage,       'praxis/skeletor/bootloader_stages/stage'
      autoload :FileLoader, 'praxis/skeletor/bootloader_stages/file_loader'
      autoload :Environment, 'praxis/skeletor/bootloader_stages/environment'
      autoload :AppLoader, 'praxis/skeletor/bootloader_stages/app_loader'
      autoload :WarnUnloadedFiles, 'praxis/skeletor/bootloader_stages/warn_unloaded_files'
      autoload :Routing, 'praxis/skeletor/bootloader_stages/routing'
    end

  end
end
