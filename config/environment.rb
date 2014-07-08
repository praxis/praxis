Praxis::Application.configure do |application|
  application.layout do
    layout do
      map :initializers, 'config/initializers/**/*'
      map :lib, 'lib/**/*'
      map :app, 'app/' do
        map :api, 'api.rb'
        map :models, 'models/**/*'
        map :media_types, '**/media_types/**/*'
        map :resources, '**/resources/**/*'

        map :controllers, '**/controllers/**/*'
        map :responses, '**/responses/**/*'
      end
    end
  end
end
