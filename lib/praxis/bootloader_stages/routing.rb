module Praxis


  module BootloaderStages

    class Routing < Stage

      def execute
        application.controllers.each do |controller|
          controller.actions.each do |action_name, action|
            action.routes.each do |route|
              target = target_factory(controller, action_name)
              application.router.add_route target, route
            end
          end
        end
      end


      def target_factory(controller, action_name)
        action = controller.action(action_name)

        Proc.new do |request|
          request.action = action
          dispatcher = Dispatcher.current( application: application)

          dispatcher.dispatch(controller, action, request)
        end
      end

    end

  end
end
