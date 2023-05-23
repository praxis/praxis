module V1
  module Concerns
    module ControllerBase
      extend ActiveSupport::Concern
      # Controller concen that wraps an API with a transaction, and automatically rolls it back
      # for non-2xx (or 3xx) responses
      included do
        around :action do |controller, callee|
          begin
            ActiveRecord::Base.transaction do
              callee.call
              res = controller.response
              # Force a rollback for non 2xx or 3xx responses
              raise ActiveRecord::Rollback unless res.status >= 200 && res.status < 400
            end
          rescue ActiveRecord::Rollback
            # No need to do anything, let the responses flow normally
          end
        end
      end
    end
  end
end