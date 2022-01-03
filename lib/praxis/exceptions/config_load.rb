# frozen_string_literal: true

module Praxis
  module Exceptions
    class ConfigLoad < Config
      def initialize(exception:)
        super(exception.message)
      end
    end
  end
end
