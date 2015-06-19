module Praxis
  module Exceptions
    class Validation < Exception

      attr_accessor :errors
      def initialize(message, errors: nil)
        super(message)
        @errors = errors
      end

    end
  end
end
