# frozen_string_literal: true

require 'singleton'

module AuthorizationPlugin
  include Praxis::PluginConcern

  class Plugin < Praxis::Plugin
    include Singleton

    def config_key
      :authorization
    end

    def initialize
      super
      @options = { config_file: 'config/authorization.yml' }
    end

    def prepare_config!(node)
      node.attributes do
        attribute :default_abilities, Attributor::Collection
      end
    end

    def default_abilities
      config.default_abilities
    end

    def authorized?(request)
      abilities = default_abilities.clone
      abilities |= request.user_abilities

      (request.action.required_abilities - abilities).empty?
    end
  end

  module Request
    def user_abilities
      []
    end
  end

  module Controller
    extend ActiveSupport::Concern

    included do
      before :action do |controller|
        verify_abilities(controller.request)
      end
    end

    module ClassMethods
      def verify_abilities(request)
        return true unless request.action.required_abilities

        authorized = AuthorizationPlugin::Plugin.instance.authorized?(request)

        return Praxis::Responses::Forbidden.new unless authorized
      end
    end

    def subject
      # p [self, :subject]
    end
  end

  module EndpointDefinition
  end

  module ActionDefinition
    extend ActiveSupport::Concern

    included do
      attr_accessor :required_abilities

      decorate_docs do |action, docs|
        docs[:required_abilities] = action.required_abilities
      end
    end

    def requires_ability(ability)
      @required_abilities ||= []
      @required_abilities << ability

      response :forbidden
      requires_authentication true
    end
  end
end
