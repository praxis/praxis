module Praxis
  module Exceptions
    class InvalidTraitException < Exception
      def initialize(message)
        super(message)
      end
    end
  end
end
