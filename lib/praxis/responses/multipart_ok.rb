module Praxis
  module Responses
    class MultipartOk < Ok

      def initialize(status:self.class.status, headers:{}, body:'')
        @name    = response_name
        @status  = status
        @headers = headers
        @body    = body
      end

      def handle
        case @body
        when Praxis::Types::MultipartArray
          if @headers['Content-Type'].nil?
            @headers['Content-Type'] = @body.content_type
          end
        end
      end


      def encode!(handlers:)
        case @body
        when Praxis::Types::MultipartArray
          @body = @body.dump
        else
          super
        end
      end

      def finish(handlers:)
        format!
        encode!(handlers: handlers)

        @body = Array(@body)

        [@status, @headers, @body]
      end

    end

  end

end
