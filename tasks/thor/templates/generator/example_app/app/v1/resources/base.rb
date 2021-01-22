# frozen_string_literal: true

module V1
  module Resources
    class Base < Praxis::Mapper::Resource
      # Base for all V1 resources.
      # Resources withing a single version should have resource mappings separate from other versions
      # and the Mapper::Resource will appropriately maintain different model_maps for each Base classes
    end
  end
end
