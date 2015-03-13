module Praxis
  module Types

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
          # TODO: parse the string and extract things like collection , and format type?...
          @identifier = identifier
        end
      end

    end

  end
end
