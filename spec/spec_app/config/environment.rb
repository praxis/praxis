class SetHeader
  def initialize(app, header, value)
    @app = app
    @header = header
    @value = value
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers[@header] = @value
    [status, headers,body]
  end
end

Praxis::Application.configure do |application|

  application.handler 'xml', Praxis::Handlers::XML

  application.middleware SetHeader, 'Spec-Middleware', 'used'

  application.bootloader.use SimpleAuthenticationPlugin, config_file: 'config/authentication.yml'
  application.bootloader.use AuthorizationPlugin

  # enable "development-mode" options
  application.config.praxis.validate_responses = true
  application.config.praxis.validate_response_bodies = true
  application.config.praxis.show_exceptions = true

  # Silly callback code pieces to test that the deferred callbacks work even for sub-stages
  application.bootloader.after :app, :controllers do
    $after_app_controllers = :worked
  end
  application.bootloader.after :app do
    raise "After sub-stage hooks not working!" unless $after_app_controllers == :worked
  end


  application.layout do
    layout do
      map :initializers, 'config/initializers/**/*'
      map :design, 'design/' do
        map :api, 'api.rb'
        map :media_types, '**/media_types/**/*'
        map :resources, '**/resources/**/*'
      end
      map :app, 'app/' do
        map :models, 'models/**/*'
        map :concerns, '**/concerns/**/*'
        map :controllers, '**/controllers/**/*'
        map :responses, '**/responses/**/*'
      end
    end
  end

end
