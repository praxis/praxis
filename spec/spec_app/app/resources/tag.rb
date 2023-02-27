# frozen_string_literal: true

require_relative 'base'

module Resources
  class Tag < Resources::Base
    model ::ActiveTag
  end
end
