Praxis::ApiDefinition.define do |api|

  api.register_response :other_response, group: :other do
    status 200
  end


  api.register_response :multipart do
    status 200
    media_type 'multipart/form-data'
  end

  # api.register_response :ok do 
  #   status 200
  #   media_type args[:media_type] || :controller_defined

  #   multipart :optional do
  #     status 200
  #     media_type 'multipart/form-data'
  #   end
  # end

  # api.register_response :abstract_multipart do
  #   status 200
  #   media_type 'multipart/form-data'
  # end

  # api.register_response :multipart do |parts: X, of: Y|
  #   status 200
  #   media_type 'multipart/form-data'
  #   parts do
  #     media_type :controller_defined
  #     status
  #   end
  # end

  api.trait :authenticated do
    headers do
      header :host
    end
  end



end
