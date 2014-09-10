require_relative 'authenticated'
require_relative 'log_wrapper'

module Concerns
  module BasicApi
    extend ActiveSupport::Concern

    # Basic Api controllers will need the Authenticated and LogWrapper concerns
    include Concerns::Authenticated
    include Concerns::LogWrapper
  end
end