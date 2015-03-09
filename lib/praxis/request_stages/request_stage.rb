module Praxis
  module RequestStages

    # Special Stage what will hijack the run and execute methods to:
    # 1- Run specific controller callbacks (in addition to any normal callbacks)
    # 2- Shortcut the controller callback chain if any returns a Response object
    class RequestStage < Stage
      extend Forwardable

      alias :dispatcher :application # it's technically application in the base Stage

      def path
        @the_path ||= [name].freeze
      end

      def execute_controller_callbacks(callbacks)
        if callbacks.key?(path)
          callbacks[path].each do |(conditions, block)|
            if conditions.key?(:actions)
              next unless conditions[:actions].include? action.name
            end
            result = block.call(controller)
            if result && result.kind_of?(Praxis::Response)
              controller.response = result
              return result
            end
          end
        end

        nil
      end

      def setup!
        setup_deferred_callbacks!
      end

      # Avoid using delegators, and create the explicit functions:
      # def_delegators :@context, :controller, :action, :request
      # they allocate all kinds of things and we don't need the generality here
      def controller
        @context.controller
      end
      def action
        @context.action
      end
      def request
        @context.request
      end

      
      def run

        # stage-level callbacks (typically empty) will never shortcut
        execute_callbacks(self.before_callbacks)

        r = execute_controller_callbacks(controller.class.before_callbacks)
        # Shortcut lifecycle if filters return non-nil value
        # (which should only be a Response)
        return r if r

        result = execute_with_around
        # Shortcut lifecycle if filters return a response
        # (non-nil but non-response-class response is ignored)
        if result && result.kind_of?(Praxis::Response)
          controller.response = result
          return result
        end

        r = execute_controller_callbacks(controller.class.after_callbacks)
        # Shortcut lifecycle if filters return non-nil value
        # (which should only be a Response)
        return r if r

        # stage-level callbacks (typically empty) will never shortcut
        execute_callbacks(self.after_callbacks)

        result
      end

      def execute_with_around
        cb = controller.class.around_callbacks[ path ]
        if cb == nil || cb.empty?
          execute
        else
          inner_proc = proc { execute }

          applicable = cb.select do |(conditions, handler)|
            if conditions.has_key?(:actions)
              (conditions[:actions].include? action.name) ? true : false
            else
              true
            end
          end

          chain = applicable.reverse.inject(inner_proc) do |blk, (conditions, handler)|
            if blk
              proc{ handler.call(controller,blk) }
            else
              proc{ handler.call }
            end
          end
          chain.call
        end
      end


      def execute
        raise NotImplementedError, 'Subclass must implement Stage#execute' unless @stages.any?

        @stages.each do |stage|
          shortcut = stage.run
          if shortcut && shortcut.kind_of?(Praxis::Response)
            controller.response = shortcut
            return shortcut 
          end
        end
        nil
      end

    end

  end
end
