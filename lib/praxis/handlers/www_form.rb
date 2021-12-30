# frozen_string_literal: true
# This is an example of a handler that can load and generate www-url-encoded payloads.
# Note that if you use your API to pass nil values for attributes as a way to unset their
# values, this handler will not work (as there isn't necessarily a defined "null" value in
# this encoding (although you can probably define how to encode/decode it and use it as such)
# Use at your own risk.
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
