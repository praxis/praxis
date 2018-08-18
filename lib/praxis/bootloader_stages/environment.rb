module Praxis

  module BootloaderStages

    class Environment < Stage

      # require environment files. we will require 2 files:
      # 1) the environment.rb file    - generic stuff for all environments
      # 2) "Deployer.environment".rb  - environment specific stuff
      def execute

        env_file = application.root + "config/environment.rb"
        require env_file if File.exists? env_file

        unless application.file_layout
          setup_default_layout!
        end
      end

      def setup_default_layout!
        application.layout do
          layout do
            map :initializers, 'config/initializers/**/*'
            map :lib, 'lib/**/*'
            map :design, 'design/' do
              map :api, 'api.rb'
              map :media_types, '**/media_types/**/*'
              map :resources, '**/resources/**/*'
            end
            map :app, 'app/' do
              map :models, 'models/**/*'
              map :controllers, '**/controllers/**/*'
              map :responses, '**/responses/**/*'
            end
          end
        end
      end


    end

  end
end
