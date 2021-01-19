# frozen_string_literal: true

module <%= version_module %>
  module Endpoints
    class <%= plural_class %>
      include Praxis::EndpointDefinition

      media_type MediaTypes::<%= singular_class %>
      version '<%= version %>'

      description 'Praxis-generated endpoint for managing <%= plural_class %>'

      action :index do
        description 'List <%= plural_class %>'
        routing { get '' }
        params do
          attribute :fields, Praxis::Types::FieldSelector.for(MediaTypes::<%= singular_class %>),
                    description: 'Fields with which to render the result.'
          attribute :pagination, Praxis::Types::PaginationParams.for(MediaTypes::<%= singular_class %>) do
            # by_fields :uid, :name
          end
          attribute :order, Praxis::Extensions::Pagination::OrderingParams.for(MediaTypes::<%= singular_class %>) do
            # by_fields :uid, :name
          end
          # # Filter by attributes. Add an allowed filter per line, with the allowed operators to use
          # # Also, remember to add a mapping for each in `filters_mapping` method of Resources::<%= singular_class %> class
          # attribute :filters, Praxis::Types::FilteringParams.for(MediaTypes::<%= singular_class %>) do
          #    filter 'first_name', using: ['=', '!='], fuzzy: true
          # end
        end
        response :ok, media_type: Praxis::Collection.of(MediaTypes::<%= singular_class %>)
      end

      action :show do
        description 'Retrieve details for a specific <%= singular_class %>'
        routing { get '/:id' }
        params do
          attribute :id, required: true
          attribute :fields, Praxis::Types::FieldSelector.for(MediaTypes::<%= singular_class %>),
                    description: 'Fields with which to render the result.'
        end
        response :ok
        response :not_found
      end


      # action :create do
      #   description 'Create a new <%= singular_class %>'
      #   routing { post '' }
      #   payload reference: MediaTypes::<%= singular_class %> do
      #     # List the attributes you accept from the one existing in the <%= singular_class %> Mediatype
      #     # and/or fully define any other ones you allow at creation time
      #     attribute :name
      #   end
      #   response :created
      #   response :bad_request
      # end

      # action :update do
      #   description 'Update one or more attributes of an existing <%= singular_class %>'
      #   routing { patch '/:id' }
      #   params do
      #     attribute :id, required: true
      #   end
      #   payload reference: MediaTypes::<%= singular_class %> do
      #     # List the attributes you accept from the one existing in the <%= singular_class %> Mediatype
      #     # and/or fully define any other ones you allow to change
      #     attribute :name
      #   end
      #   response :no_content
      #   response :bad_request
      # end

      # action :delete do
      #   description 'Deletes a <%= singular_class %>'
      #   routing { delete '/:id' }
      #   params do
      #     attribute :id, required: true
      #   end
      #   response :no_content
      #   response :not_found
      # end
    end
  end
end

