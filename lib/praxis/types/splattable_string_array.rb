# frozen_string_literal: true

module Praxis
  module Types
    class SplattableStringArray < Attributor::Collection
      # Make a type, to allow to load the value, as s single string, if it isn't a numerable
      # This way we can do displayable: 'foobar' , or displayable: ['one', 'two']
      def self.decode_string(value, _context)
        Array(value)
      end
    end
  end
end
