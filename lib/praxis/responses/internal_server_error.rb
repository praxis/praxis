module Praxis
  module Responses
    # A generic error message, given when an unexpected condition was encountered and no more specific message is suitable.
    class InternalServerError < Praxis::Response
      self.status = 500
      attr_accessor :error

      def initialize(error: nil, **opts)
        super(**opts)
        @headers['Content-Type'] = 'application/json' # TODO: might want an error mediatype
        @error = error
      end

      def format!(exception = @error)
        if @error

          if Application.instance.config.praxis.show_exceptions == true
            msg = {
              name: exception.class.name,
              message: exception.message,
              backtrace: exception.backtrace
            }
            msg[:cause] = format!(exception.cause) if exception.cause
          else
            msg = { name: 'InternalServerError', message: 'Something bad happened.' }
          end

          @body = msg
        end
      end
    end
  end

  ApiDefinition.define do |api|
    api.response_template :internal_server_error do
      description 'A generic error message, given when an unexpected condition was encountered and no more specific message is suitable.'
      status 500
      media_type 'application/json'
    end
  end
end
