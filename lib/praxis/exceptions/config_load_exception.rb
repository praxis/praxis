module Praxis
  module Exceptions
    class ConfigLoadException < ConfigException
      def initialize(exception:)
        super(exception.message)
      end
    end
  end
end
