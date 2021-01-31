# frozen_string_literal: true

module V1
  module Controllers
    class Users
      include Praxis::Controller
      include Concerns::ControllerBase

      implements V1::Endpoints::Users

      def index
        objects = build_query(::User)
        display(objects)
      end
    end
  end
end
