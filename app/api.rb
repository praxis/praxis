Praxis::ApiDefinition.define do |api|

  api.register_response :other_response, group: :other do |media_type: |
    status 200
    media_type media_type
  end


  api.register_response :multipart do 
    status 200
    media_type 'multipart/form-data'
 #   
 #   parts like: :default, media_type: Instance
 #
 #   parts do
 #     status 201
 #     media_type Instance
 #   end
 #   
 #   part "foobar", like: :other_response, media_type: Instance
 #   
 #   part "file" do
 #     media_type  MyType
 #     #header "Status", 201
 #     #location /asdfa/
 #   end
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
