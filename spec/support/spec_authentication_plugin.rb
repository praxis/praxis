require 'singleton'

class Authenticator
  include Attributor::Type

  def self.native_type
    Class
  end

  def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
    case value
    when Hash
      type = value.delete(:type) || value.delete('type')
      Object.const_get(type).new(**value)
    when self
      value
    else
      raise "#{self.naem} can not load values of type #{value.class}"
    end
  end

  def self.validate(*args)
  end

  def self.describe
  end

  def initialize(**options)
  end

  def authenticate(request)
    raise "sublcass must implement authenticate"
  end

end


class GlobalSessionAuthenticator < Authenticator

  def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
    self.new(**value)
  end

  def self.describe
  end

  def initialize(**options)
  end

  def authenticate(request)
    body = {name: 'Unauthorized'}

    if (session = request.env['global_session'])
      return true if session.valid?
      body[:message] = 'Invalid session.'
    else
      body[:message] = 'Missing session.'
    end

    Praxis::Responses::Unauthorized.new(body: body)
  end

end


module AuthenticationPlugin
  include Praxis::PluginConcern

  class Plugin < Praxis::Plugin
    include Singleton

    def initialize
      @options = {config_file: 'config/authentication.yml'}
    end

    def config_key
      :authentication
    end

    def prepare_config!(node)
      self.config_attribute = Attributor::Attribute.new(Authenticator, required: true)
    end

    def self.authenticate(request)
      instance.config.authenticate(request)
    end

  end


  module Request
  end

  module Controller
    extend ActiveSupport::Concern

    included do
      before :action do |controller|
        if controller.request.action.authentication_required
          Plugin.authenticate(controller.request)
        end
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
