module Praxis
  module Handlers
    class Plain
      # no-op
      def parse(entity)
        entity
      end

      # no-op
      def generate(structured_data)
        structured_data
      end
    end
  end
end
