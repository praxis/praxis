module Praxis
  module Exceptions
    class ConfigValidation < Config
      def initialize(errors:)
        super('Validation error: ' << errors.join('; '))
      end
    end
  end
end
