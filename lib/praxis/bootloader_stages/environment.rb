module Praxis


  module BootloaderStages

    class Environment < Stage

      # require environment files. we will require 2 files:
      # 1) the environment.rb file    - generic stuff for all environments
      # 2) "Deployer.environment".rb  - environment specific stuff
      def execute
        env_file = application.root + "config/environment.rb"
        require env_file if File.exists? env_file

        application.plugins.each do |plugin|
          plugin.setup!
        end

        unless application.file_layout
          setup_default_layout!
        end

        setup_initial_config!
      end

      def setup_default_layout!
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

      # TODO: not really sure I like this here... but where else is better?
      def setup_initial_config!
        application.config do
          attribute :praxis do
            attribute :validate_responses, Boolean, default: false
          end
        end
      end

    end

  end
end
