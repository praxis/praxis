module Praxis
  module Exceptions
    class ConfigValidationException < ConfigException
      def initialize(errors:)
        super('Validation error: ' << errors.join('; '))
      end
    end
  end
end
