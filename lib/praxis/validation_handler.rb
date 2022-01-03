# frozen_string_literal: true

module Praxis
  class ValidationHandler
    # Should return the Response to send back
    def handle!(summary:, errors: nil, exception: nil, **opts)
      opts.delete(:request)
      opts.delete(:stage)
      Responses::ValidationError.new(summary: summary, errors: errors, exception: exception, **opts)
    end
  end
end
