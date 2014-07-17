module Praxis
  class MultipartPart

    attr_accessor :body, :headers, :filename
    def initialize(body, headers={}, filename:nil)
      @body = body
      @headers = headers
      @filename = filename
    end

  end
end
