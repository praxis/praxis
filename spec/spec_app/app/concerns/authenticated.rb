module Concerns
  module Authenticated
    extend ActiveSupport::Concern
    include Praxis::Callbacks
    
    included do
      before :action do |controller|
        auth_data = controller.request.headers['Authorization']
        if auth_data && auth_data !~ /secret/ 
          Praxis::Responses::Unauthorized.new(body: 'Authentication info is invalid')
        end
      end
    end
  end
end