module Praxis


  module BootloaderStages

    class Routing < Stage
      class Target
        attr_reader :action
        def initialize(application, controller, action)
          @application = application
          @controller = controller
          @action = action
        end
        
        def call(request)
          request.action = @action
          dispatcher = Dispatcher.current( application: @application)

          dispatcher.dispatch(@controller, @action, request)
        end
      end
      
      def execute
        application.controllers.each do |controller|
          controller.definition.actions.each do |action_name, action|
            action.routes.each do |route|
              target = target_factory(controller, action_name)
              application.router.add_route target, route
            end
          end
        end
      end


      def target_factory(controller, action_name)
        action = controller.definition.actions.fetch(action_name)

        Target.new(application, controller, action)
      end

    end

  end
end
