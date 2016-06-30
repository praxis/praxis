module Praxis
  class ValidationHandler

    # Should return the Response to send back
    def handle!(summary:, request:, stage:, errors: nil, exception: nil, documentation: nil, **opts)
      Responses::ValidationError.new(summary: summary, errors: errors, exception: exception, documentation: documentation, **opts)
    end

  end
end
