# frozen_string_literal: true

require_relative 'base'

module Resources
  class Tagging < Resources::Base
    model ::ActiveTagging
  end
end
