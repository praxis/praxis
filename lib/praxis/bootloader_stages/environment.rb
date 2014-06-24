module Praxis


  module BootloaderStages

    class Environment < Stage

      # require environment files. we will require 2 files:
      # 1) the environment.rb file    - generic stuff for all environments
      # 2) "Deployer.environment".rb  - environment specific stuff
      def execute
        #require application.root + "config/environment.rb"
        #require application.root + "config/environments"

        application.plugins.each do |plugin|
          plugin.setup!
        end

        unless application.file_layout
          setup_default_layout!
        end
      end

      def setup_default_layout!
        application.bootloader.layout do
          layout do
            map :initializers, 'config/initializers/**/*'
            #map :lib, 'lib/**/*'
            map :app, 'app/' do
              map :models, 'models/**/*'
              map :resources, '**/resources/**/*'
              map :media_types, '**/media_types/**/*'
              map :controllers, '**/controllers/**/*'
            end
          end
        end
      end


    end

  end
end
