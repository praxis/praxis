# frozen_string_literal: true

require_relative '../concerns/href'

module V1
  module Resources
    class Base < Praxis::Mapper::Resource
      include Resources::Concerns::Href

      # Base for all V1 resources.
      # Resources withing a single version should have resource mappings separate from other versions
      # and the Mapper::Resource will appropriately maintain different model_maps for each Base classes
    end
  end
end
