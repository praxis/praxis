# frozen_string_literal: true

module Concerns
  module LogWrapper
    extend ActiveSupport::Concern
    include Praxis::Callbacks

    included do
      before :around do |_controller, callee|
        # Log something at the beginning
        callee.call
        # Log something at the end
      end
    end
  end
end
