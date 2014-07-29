module Praxis
  module Responses
    class Default < Praxis::Response
      self.response_name = :ok

      def handle
        @status = 200
      end

    end

   end
end
