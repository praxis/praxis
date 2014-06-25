Praxis::ApiDefinition.define do |api|

  api.register_response :other_response, group: :other do
    status 200
  end

  api.trait :authenticated do
    headers do
      header :host
    end
  end

end
