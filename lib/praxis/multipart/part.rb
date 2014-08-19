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
