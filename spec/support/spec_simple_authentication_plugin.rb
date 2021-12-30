require 'singleton'

module SimpleAuthenticationPlugin
  include Praxis::PluginConcern

  class Plugin < Praxis::Plugin
    include Singleton

    def initialize
      @options = { config_file: 'config/authentication.yml' }
    end

    def config_key
      :authentication
    end

    def prepare_config!(node)
      node.attributes do
        attribute :authentication_default, Attributor::Boolean, default: false
      end
    end

    def self.authenticate(request)
      request.current_user == 'guest'
    end
  end

  module Request
    def current_user
      'guest'
    end
  end

  module Controller
    extend ActiveSupport::Concern

    included do
      before :action do |controller|
        action = controller.request.action
        Plugin.authenticate(controller.request) if action.authentication_required
      end
    end
  end

  module ActionDefinition
    extend ActiveSupport::Concern

    included do
      decorate_docs do |action, docs|
        docs[:authentication_required] = action.authentication_required
      end
    end

    def requires_authentication(value)
      @authentication_required = value
    end

    def authentication_required
      @authentication_required ||= false
    end
  end
end
