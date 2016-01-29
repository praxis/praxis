Praxis::ApiDefinition.define do

  response_template :other_response do |media_type:|
    status 200
    media_type media_type
  end

  response_template :multipart do
    status 200
    media_type 'multipart/form-data'
  end



  trait :authenticated do
    headers do
      key "Authorization", String, required: false
    end
  end

  info do # applies to all API infos
    name "Spec App"
    title "A simple App to do some simple integration testing"
    description "This example API should really be replaced by a set of more full-fledged example apps in the future"

    base_path "/api"
    produces 'json','xml'
    #version_with :path
    #base_path "/v:api_version"

    # Custom attributes (for OpenApi, for example)
    termsOfService "http://example.com/tos"
    contact name: 'Joe', email: 'joe@email.com'
    license name: "Apache 2.0",
            url: "https://www.apache.org/licenses/LICENSE-2.0.html"
  end

  info '1.0' do # Applies to 1.0 version (and inherits everything else form the global one)
    description "A simple 1.0 App"
  end

end
