# frozen_string_literal: true

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
          dispatcher = Dispatcher.current(application: @application)
          # Switch to the sister get action if configured that way (and mark the request as forwarded)
          action = \
            if @action.sister_get_action
              request.forwarded_from_action = @action
              @action.sister_get_action
            else
              @action
            end
          dispatcher.dispatch(@controller, action, request)
        end
      end

      def execute
        application.controllers.each do |controller|
          controller.definition.actions.each do |action_name, action|
            target = target_factory(controller, action_name)
            application.router.add_route target, action.route
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
