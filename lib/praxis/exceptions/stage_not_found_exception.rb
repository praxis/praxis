module Praxis
  module Exceptions
    class StageNotFoundException < Exception
      def initialize(message)
        super(message)
      end
    end
  end
end
