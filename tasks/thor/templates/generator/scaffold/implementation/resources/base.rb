# frozen_string_literal: true

module <%= version_module %>
  module Resources
    class Base < Praxis::Mapper::Resource
      # Base for all <%= version_module %> resources.
      # Resources withing a single version should have resource mappings separate from other versions
      # and the Mapper::Resource will appropriately maintain different model_maps for each Base classes
    end
  end
end
