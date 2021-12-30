module Praxis
  class << self
    attr_writer :request_superclass

    def request_superclass
      @request_superclass || Object
    end
  end
end
