module Praxis


  module BootloaderStages

    class Routing < Stage

      def execute
        application.controllers.each do |controller|
          controller.actions.each do |action_name, action|
            action.routing_config.routes.each do |(verb, path, opts)|
              target = target_factory(controller, action_name)
              application.router.add_route target,
                path: Mustermann.new(path),
                verb: verb,
                version: controller.definition.version
            end
          end
        end
      end


      def target_factory(controller, action_name)
        action = controller.action(action_name)

        Proc.new do |request|
          request.action = action
          Dispatcher.dispatch(controller, action, request)
        end
      end

    end

  end
end
