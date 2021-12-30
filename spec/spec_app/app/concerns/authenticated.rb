module Concerns
  module Authenticated
    extend ActiveSupport::Concern
    include Praxis::Callbacks

    included do
      before :action do |controller|
        auth_data = controller.request.headers['Authorization']
        Praxis::Responses::Unauthorized.new(body: 'Authentication info is invalid') if auth_data && auth_data !~ /secret/
      end
    end
  end
end
