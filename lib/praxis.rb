require 'attributor'
require 'active_support/inflector'
$:.unshift File.dirname(__FILE__)

module Praxis
  autoload :Controller, 'praxis/controller'
  autoload :Response, 'praxis/response'
  autoload :Request, 'praxis/request'

  module Skeletor
    autoload :ResponseDefinition, 'praxis/skeletor/response_definition'
    autoload :RestfulActionConfig, 'praxis/skeletor/restful_action_config'
    autoload :RestfulSinatraApplicationConfig, 'praxis/skeletor/restful_sinatra_application_config'
    autoload :RestfulRoutingConfig, 'praxis/skeletor/restful_routing_config'
  end
end
