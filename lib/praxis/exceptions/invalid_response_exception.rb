module Praxis
  module Exceptions
    class InvalidResponseException < Exception
      def initialize(message)
        super(message)
      end
    end
  end
end
