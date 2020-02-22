module Praxis
  class ErrorHandler

    def handle!(request, error)
      Application.instance.logger.error error.inspect
      error.backtrace.each do |line|
        Application.instance.logger.error line
      end

      response = Responses::InternalServerError.new(error: error)
      response.request = request
      response.finish
    end

  end
end
