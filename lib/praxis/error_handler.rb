module Praxis
  class ErrorHandler
    
    def handle!(request, error, app:)
      app.logger.error error.inspect
      error.backtrace.each do |line|
        app.logger.error line
      end

      response = Responses::InternalServerError.new(error: error)
      response.request = request
      response.finish(application: app)
    end

  end
end
