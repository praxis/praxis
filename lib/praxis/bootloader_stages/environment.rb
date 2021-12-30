# frozen_string_literal: true
module Praxis
  module BootloaderStages
    class Environment < Stage
      # require environment files. we will require 2 files:
      # 1) the environment.rb file    - generic stuff for all environments
      # 2) "Deployer.environment".rb  - environment specific stuff
      def execute
        setup_initial_config!

        env_file = application.root + 'config/environment.rb'
        require env_file if File.exist? env_file

        setup_default_layout! unless application.file_layout
      end

      def setup_default_layout!
        application.layout do
          map :initializers, 'config/initializers/**/*'
          map :lib, 'lib/**/*'
          map :design, 'design/' do
            map :api, 'api.rb'
            map :helpers, '**/helpers/**/*'
            map :types, '**/types/**/*'
            map :media_types, '**/media_types/**/*'
            map :endpoints, '**/endpoints/**/*'
          end
          map :app, 'app/' do
            map :models, 'models/**/*'
            map :responses, '**/responses/**/*'
            map :exceptions, '**/exceptions/**/*'
            map :concerns, '**/concerns/**/*'
            map :resources, '**/resources/**/*'
            map :controllers, '**/controllers/**/*'
          end
        end
      end

      # TODO: not really sure I like this here... but where else is better?
      def setup_initial_config!
        application.config do
          attribute :praxis do
            attribute :validate_responses, Attributor::Boolean, default: false
            attribute :validate_response_bodies, Attributor::Boolean, default: false

            attribute :show_exceptions, Attributor::Boolean, default: false
            attribute :x_cascade, Attributor::Boolean, default: true
          end
        end
      end
    end
  end
end
