# frozen_string_literal: true

module <%= version_module %>
  module Controllers
    class <%= plural_class %>
      include Praxis::Controller

      implements Endpoints::<%= plural_class %>

      # Retrieve all <%= plural_class %> with the right necessary associations
      # and render them appropriately with the requested field selection
      def index
        objects = build_query(model_class).all
        display(objects)
      end

      # Retrieve a single <%= singular_class %> with the right necessary associations
      # and render them appropriately with the requested field selection
      def show(id:, **_args)
        model = build_query(model_class.where(id: id)).first
        return Praxis::Responses::NotFound.new if model.nil?

        display(model)
      end

      # # Creates a new <%= singular_class %>
      # def create
      #   # A good pattern is to call the same name method on the corresponding resource, 
      #   # passing the incoming payload, or massaging it first
      #   created_resource = Resources::<%= singular_class%>.create(request.payload)

      #   # Respond with a created if it successfully finished
      #   Praxis::Responses::Created.new(location: created.href)
      # end

      # # Updates some of the information of a <%= singular_class %>
      # def update(id:)
      #   # Retrieve the model from the DB
      #   model = model_class.find_by(id: id)
      #   return Praxis::Responses::NotFound.new unless model

      #   # A good pattern is to call the same name method on the corresponding resource, 
      #   # passing the incoming payload, or massaging it first
      #   Resources::<%= singular_class %>.update(
      #     model: model,
      #     payload: request.payload,
      #   )

      #   Praxis::Responses::NoContent.new
      # end


      # # Deletes an existing <%= singular_class %>
      # def delete(id:)
      #   # Retrieve the model from the DB
      #   model = model_class.find_by(id: id)
      #   return Praxis::Responses::NotFound.new unless model

      #   # A good pattern is to call the same name method on the corresponding resource,
      #   # maybe passing the already loaded model
      #   Resources::<%= singular_class %>.update(model: model)

      #   Praxis::Responses::NoContent.new
      # end

      # Use the model class as the base query but you might want to change that
      def model_class
        ::<%= singular_class %> #Change it to the appropriate DB model class
      end
    end
  end
end