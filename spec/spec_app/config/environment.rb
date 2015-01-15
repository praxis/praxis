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

  application.middleware SetHeader, 'Spec-Middleware', 'used'

  application.bootloader.use SimpleAuthenticationPlugin, config_file: 'config/authentication.yml'
  application.bootloader.use AuthorizationPlugin

  application.bootloader.use Praxis::Plugins::PraxisMapperPlugin, {
    config_data: {
      repositories: { default: {adapter: 'sqlite', database: ':memory:'} }
    }
  }

  # enable "development-mode" options
  application.config.praxis.validate_responses = true
  application.config.praxis.show_exceptions = true

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
