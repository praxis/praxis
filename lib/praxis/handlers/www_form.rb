module Praxis
  module Handlers
    class WWWForm
      def initialize
        require 'rack' # superfluous, but might as well be safe
      end

      # Parse a URL-encoded WWW form into structured data.
      def parse(entity)
        ::Rack::Utils.parse_nested_query(entity)
      end

      # Generate a URL-encoded WWW form from structured data. Not implemented since this format
      # is not very useful for a response body.
      def generate(structured_data)
        return nil if structured_data.nil?
        URI.encode_www_form(structured_data)
      end
    end
  end
end