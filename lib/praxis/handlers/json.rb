# frozen_string_literal: true

module Praxis
  module Handlers
    class JSON
      # Construct a JSON handler and initialize any related libraries.
      #
      # @raise [Praxis::Exceptions::InvalidConfiguration] if the handler is unsupported
      def initialize
        require 'oj'
        begin
          require 'json'
        rescue LoadError # rubocop:disable Lint/SuppressedException
        end
        # Enable mimicing needs to be done after loading the JSON gem (if there)
        ::Oj.mimic_JSON
      rescue LoadError
        # Should never happen since JSON is a default gem; might as well be cautious!
        raise Praxis::Exceptions::InvalidConfiguration,
              'JSON handler depends on oj ~> 3; please add it to your Gemfile'
      end

      # Parse a JSON document into structured data.
      #
      # @param [String] document
      # @return [Hash,Array] the structured-data representation of the document
      def parse(document)
        # Try to be nice and accept an empty string as an empty payload (seems nice to do for dumb http clients)
        return nil if document.nil? || document == ''

        ::Oj.load(document)
      end

      # Generate a pretty-printed JSON document from structured data.
      #
      # @param [Hash,Array] structured_data
      # @return [String]
      def generate(structured_data)
        ::Oj.dump(structured_data, indent: 2)
      end
    end
  end
end
