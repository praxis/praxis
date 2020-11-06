# frozen_string_literal: true

module V1
  module Controllers
    class Users
      include Praxis::Controller
      include Praxis::Extensions::Rendering
      
      implements V1::Endpoints::Users

      def index
        query1 = build_query(::User)
        objects = handle_pagination(query: query1, type: :active_record).all
        display(objects)
      end
    end
  end
end
