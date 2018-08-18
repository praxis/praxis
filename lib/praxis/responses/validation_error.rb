module Praxis

  module Responses

    class ValidationError < BadRequest
      def initialize(summary:, errors: nil, exception: nil, documentation: nil, **opts)
        super(**opts)
        @headers['Content-Type'] = 'application/json' #TODO: might want an error mediatype
        @errors = errors
        unless @errors # The exception message will the the only error if no errors are passed in
           @errors = [exception.message] if exception && exception.message
         end
        @exception = exception
        @summary = summary
        @documentation = documentation
      end

      def format!(**_args)
        @body = {name: 'ValidationError', summary: @summary }
        @body[:errors] = @errors if @errors

        if @exception && @exception.cause
          @body[:cause] = {name: @exception.cause.class.name, message: @exception.cause.message}
        end

        @body[:documentation] = @documentation if @documentation

        @body
      end
    end

  end

end
