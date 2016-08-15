module Praxis
  class ValidationHandler

    # Should return the Response to send back
    def handle!(summary:, request:, stage:, errors: nil, exception: nil, **opts)
      documentation = Docs::LinkBuilder.instance.for_request request
      Responses::ValidationError.new(summary: summary, errors: errors, exception: exception, documentation: documentation, **opts)
    end

  end
end
