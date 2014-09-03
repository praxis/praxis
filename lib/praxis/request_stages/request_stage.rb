module Praxis
  module RequestStages

    # Special Stage what will hijack the run and execute methods to:
    # 1- Run specific controller callbacks (in addition to any normal callbacks)
    # 2- Shortcut the controller callback chain if any returns a Response object
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
            result = block.call(controller)
            return result if result && result.kind_of?(Praxis::Response)
          end
        end
        nil
      end
      
      def run
        setup!
        setup_deferred_callbacks!
        
        execute_callbacks(self.before_callbacks)
        # Shortcut lifecycle if filters return a response (non-nil but non-response-class response is ignored)
        r = execute_controller_callbacks(controller.class.before_callbacks)
        return r if r

        result = execute
        
        # Still allow the after callbacks to shortcut it if necessary.
        r = execute_controller_callbacks(controller.class.after_callbacks)
        return r if r 
        execute_callbacks(self.after_callbacks) 

        result
      end

      def execute
        raise NotImplementedError, 'Subclass must implement Stage#execute' unless @stages.any?

        @stages.each do |stage|
          r = stage.run
          return r if r && r.kind_of?(Praxis::Response)
        end
        nil
      end

    end

  end
end
