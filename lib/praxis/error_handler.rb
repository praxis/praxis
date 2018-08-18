module Praxis
  class ErrorHandler
    attr_reader :praxis_instance
    
    def initialize(praxis_instance:)
      @praxis_instance = praxis_instance
    end
    def handle!(request, error)
      # TODO SINGLETON: ... this is probably right...or maybe we can get to the actual instance?...
      praxis_instance.logger.error error.inspect
      error.backtrace.each do |line|
        praxis_instance.logger.error line
      end

      response = Responses::InternalServerError.new(error: error)
      response.request = request
      response.finish(handlers: praxis_instance.handlers)
    end

  end
end
