# frozen_string_literal: true

module <%= version_module %>
  module MediaTypes
    class <%= singular_class %> < Praxis::MediaType
      identifier 'application/json'

      domain_model '<%= version_module %>::Resources::<%= singular_class %>'
      description 'Structural definition of a <%= singular_class %>'

      attributes do
        attribute :id, Integer, description: '<%= singular_class %> identifier'
        # Define as many attributes with types as required (and/or delete id above)
      end
    end
  end
end

