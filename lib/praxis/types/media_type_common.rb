module Praxis
  module Types

    # Traits that are shared by MediaType and SimpleMediaType.
    module MediaTypeCommon
      extend ::ActiveSupport::Concern

      module ClassMethods
        def describe(shallow = false)
          hash = super
          unless shallow
            hash.merge!(identifier: @identifier, description: @description)
          end
          hash
        end

        def description(text=nil)
          @description = text if text
          @description
        end

        def identifier(identifier=nil)
          return @identifier unless identifier
          @identifier = MediaTypeIdentifier.load(identifier)
        end
      end

    end

  end
end
