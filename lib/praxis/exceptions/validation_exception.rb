module Praxis
  module Exceptions
    class ValidationException < Exception
      def initialize(message)
        super(message)
      end
    end
  end
end
