module Praxis
  module Responses
    class NotFound < Praxis::Response
      self.response_name = :not_found

      def handle
        @status = 404
        puts "handling: #{@name}"
      end

    end
  end
end
