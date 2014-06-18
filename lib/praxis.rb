require 'rack'

require 'attributor'
require 'active_support/inflector'

$:.unshift File.dirname(__FILE__)

module Praxis
  autoload :Application, 'praxis/application'
  autoload :Controller, 'praxis/controller'
  autoload :Response, 'praxis/response'
  autoload :Request, 'praxis/request'
  autoload :Router, 'praxis/router'

  module Skeletor
    autoload :ResponseDefinition, 'praxis/skeletor/response_definition'
    autoload :RestfulActionConfig, 'praxis/skeletor/restful_action_config'
    autoload :RestfulSinatraApplicationConfig, 'praxis/skeletor/restful_sinatra_application_config'
    autoload :RestfulRoutingConfig, 'praxis/skeletor/restful_routing_config'
  end
end
