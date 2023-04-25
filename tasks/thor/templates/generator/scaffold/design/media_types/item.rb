# frozen_string_literal: true

module <%= version_module %>
  module MediaTypes
    class <%= singular_class %> < Praxis::MediaType
      identifier 'application/json'

      domain_model 'Resources::<%= singular_class %>'
      description 'Structural definition of a <%= singular_class %>'

      attributes do
        attribute :id, Integer, description: '<%= singular_class %> identifier'
        # <INSERT MORE ATTRIBUTES HERE>
      end
    end
  end
end

