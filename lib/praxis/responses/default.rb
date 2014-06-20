module Praxis
  module Responses
    class Default < Praxis::Response
      self.response_name = :default

      def handle
        @status = 200
      end

    end
  end
end
