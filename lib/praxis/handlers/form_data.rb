module Praxis
  module Handlers
    class FormData

      # Construct a Multipart Form-Data handler and initialize any related libraries.
      #
      # @raise [Praxis::Exceptions::InvalidConfiguration] if the handler is unsupported
      def initialize
      end

      # Parse a Multipart Form-Data document into structured data.
      #
      # @param [String] document
      # @return [MultipartArray] the structured-data representation of the document
      def parse(document)
        # FIXME: do something
        document
      end

      # Generate a string from structured data.
      #
      # @param [MultipartArray, Hash, Array] structured_data
      # @return [String]
      def generate(structured_data)
        # FIXME: do something
        structured_data
      end
      
    end
  end
end
