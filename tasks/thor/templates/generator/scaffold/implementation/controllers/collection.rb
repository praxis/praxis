# frozen_string_literal: true

module <%= version_module %>
  module Controllers
    class <%= plural_class %>
      include Praxis::Controller

      implements Endpoints::<%= plural_class %>

      <%- if action_enabled?(:index) -%>
      # Retrieve all <%= plural_class %> with the right necessary associations
      # and render them appropriately with the requested field selection
      def index
        objects = build_query(model_class)
        display(objects)
      end
      <%- end -%>

      <%- if action_enabled?(:show) -%>
      # Retrieve a single <%= singular_class %> with the right necessary associations
      # and render them appropriately with the requested field selection
      def show(id:, **_args)
        model = build_query(model_class.where(id: id)).first
        return Praxis::Responses::NotFound.new if model.nil?

        display(model)
      end
      <%- end -%>

      <%- if action_enabled?(:create) -%>
      # Creates a new <%= singular_class %>
      def create
        # A good pattern is to call the same name method on the corresponding resource, 
        # passing the incoming payload, or massaging it first
        created_resource = Resources::<%= singular_class%>.create(request.payload)

        # Respond with a created if it successfully finished
        Praxis::Responses::Created.new(location: created_resource.href)
      end
      <%- end -%>

      <%- if action_enabled?(:update) -%>
      # Updates some of the information of a <%= singular_class %>
      def update(id:)
        # A good pattern is to retrieve the resource instance by id, and then
        # call the same name method on it, by passing the incoming payload (or massaging it first)
        resource = Resources::<%= singular_class %>.get(id: id)
        return Praxis::Responses::NotFound.new unless resource

        resource.update(payload: request.payload)
        Praxis::Responses::NoContent.new
      end
      <%- end -%>

      <%- if action_enabled?(:delete) -%>
      # Deletes an existing <%= singular_class %>
      def delete(id:)
        # A good pattern is to retrieve the resource instance by id, and then
        # call the same name method on it
        resource = Resources::<%= singular_class %>.get(id: id)
        return Praxis::Responses::NotFound.new unless resource

        resource.delete(payload: request.payload)
        Praxis::Responses::NoContent.new
      end
      <%- end -%>

      # Use the model class as the base query but you might want to change that
      def model_class
        ::<%= singular_class %> #Change it to the appropriate DB model class
      end
    end
  end
end