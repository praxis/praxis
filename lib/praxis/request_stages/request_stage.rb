module Praxis
  module RequestStages

    class RequestStage < Stage
      extend Forwardable

      def_delegators :@context, :controller, :action, :request
      alias :dispatcher :application # it's technically application in the base Stage

      def path
        [name]
      end

      def execute_controller_callbacks(callbacks)
        if callbacks.has_key?(path)
          callbacks[path].each do |(conditions, block)|
            if conditions.has_key?(:actions)
              next unless conditions[:actions].include? action.name
            end
            block.call(controller)
          end
        end
      end

      def run
        setup!
        setup_deferred_callbacks!
        execute_callbacks(self.before_callbacks)
        execute_controller_callbacks(controller.class.before_callbacks)
        result = execute
        execute_controller_callbacks(controller.class.after_callbacks)
        execute_callbacks(self.after_callbacks)

        result
      end


      def execute
        raise NotImplementedError, 'subclass must implement Stage#execute' unless @stages.any?

        @stages.each do |stage|
          result = stage.run
          return result if result.kind_of?(Praxis::Response)
        end

        nil
      end

    end

  end
end
