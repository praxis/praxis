module Praxis
  module Types

    # Traits that are shared by MediaType and SimpleMediaType.
    module MediaTypeCommon
      extend ::ActiveSupport::Concern

      module ClassMethods
        def describe(shallow = false, **opts)
          hash = super
          unless shallow
            hash.merge!(identifier: @identifier.to_s, description: @description, display_name: self.display_name)
          end
          hash
        end

        def as_json_schema(**args)
          the_type = @attribute && @attribute.type || member_type
          the_type.as_json_schema(args)
        end

        def json_schema_type
          the_type = @attribute && @attribute.type || member_type
          the_type.json_schema_type
        end
    
        def description(text=nil)
          @description = text if text
          @description
        end

        def display_name( string=nil )
          unless string
            return  @display_name ||= self.name.split("::").last  # Best guess at a display name?
          end
          @display_name = string
        end

        # Get or set the identifier of this media type.
        #
        # @deprecated this method is not deprecated, but its return type will change to MediaTypeIdentifier in Praxis 1.0
        #
        # @return [MediaTypeIdentifier] the string-representation of this type's identifier
        def identifier(identifier=nil)
          return @identifier unless identifier
          @identifier = MediaTypeIdentifier.load(identifier)
        end
      end

    end

  end
end
