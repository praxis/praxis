module Praxis
  class MultipartPart

    attr_accessor :body
    attr_accessor :headers
    attr_accessor :filename
    
    def initialize(body, headers={}, filename: nil)
      @body = body
      @headers = headers
      @filename = filename
    end

    # Determine the content type of this response.
    #
    # @return [MediaTypeIdentifier]
    def content_type
      MediaTypeIdentifier.load(headers['Content-Type']).freeze
    end

    # Set the content type for this response.
    # @todo DRY this out (also used in Response)
    #
    # @return [String]
    # @param [String,MediaTypeIdentifier] identifier
    def content_type=(identifier)
      headers['Content-Type'] = MediaTypeIdentifier.load(identifier).to_s
    end

    def status
      @headers['Status'].to_i
    end

    def encode!
      case @body
      when Hash, Array
        @body = JSON.pretty_generate(@body)
      end
    end

  end
end
