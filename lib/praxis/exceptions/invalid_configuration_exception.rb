module Praxis
  module Exceptions
    class InvalidConfigurationException < Exception
      def initialize(message)
        super(message)
      end
    end
  end
end
