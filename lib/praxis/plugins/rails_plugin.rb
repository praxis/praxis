require 'praxis/plugin'
require 'praxis/plugin_concern'

module Praxis
  module Plugins
    module RailsPlugin
      include Praxis::PluginConcern

      class Plugin < Praxis::Plugin

        def setup!
          require 'praxis/dispatcher'
          enable_action_controller_instrumentation
        end

        private
        def enable_action_controller_instrumentation
          Praxis::Dispatcher.class_eval do
            # Wrap the original action dispatch with a method that instruments rails-expected bits...
            alias_method :orig_instrumented_dispatch, :instrumented_dispatch

            def instrumented_dispatch( praxis_payload )
              rails_payload = {
                :controller => controller.class.name,
                :action     => action.name,
                :params     => ( (request.params) ? request.params.dump : {} ),
                :method     => request.verb,
                :path       => (request.fullpath rescue "unknown")
              }
              Praxis::Notifications.instrument("start_processing.action_controller", rails_payload.dup)

              Praxis::Notifications.instrument 'process_action.action_controller' do |data|
                begin
                  res = orig_instrumented_dispatch(praxis_payload)
                  # TODO: also add the db_runtime and view_runtime values...
                  data[:status] = res[0]
                  res
                ensure
                  # Append DB runtime to payload
                  #data[:db_runtime] = 999
                  # Append rendering time to payload
                  #data[:view_runtime] = 123
                end
              end
            end
          end
        end
      end

      module Request
      end

      module Controller
        extend ActiveSupport::Concern

        # Throw in some basic and expected controller methods

        # Expose a rails-version of params from the controller
        # Avoid using them explicitly in your controllers though. Use request.params object instead, as they are
        # the Praxis ones that have been validated and coerced into the types you've defined.
        def params
          self.request.parameters
        end

        # Allow accessing the response headers from the controller
        def headers
          self.response.headers
        end

        def session
          self.request.session
        end

        # Allow setting the status and body of the response from the controller itself.
        def status=(code)
          self.response.status = code
        end

        def response_body=(body)
          #TODO: @_rendered = true # Necessary to know if to stop filter chain or not...
          self.response.body = body
        end

      end

    end
  end
end
