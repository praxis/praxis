Praxis::ApiDefinition.define do

  response_template :other_response do |media_type:|
    status 200
    media_type media_type
  end

  response_template :multipart do
    status 200
    media_type 'multipart/form-data'
  end

  response_template :bulk_response do |media_type: nil, parts: |
    status 200
    media_type 'multipart/form-data'

    parts[:media_type] ||= media_type if ( media_type && parts.kind_of?(Hash) )
    parts(parts)
  end

  trait :authenticated do
    headers do
      key "Authorization", String, required: false
    end
  end

  info do # applies to all API infos
    name "Spec App"
    title "A simple App to do some simple integration testing"
    description "This example API should really be replaced by a set of more ful-fledged example apps in the future"
  end
  
  info("1.0") do # Applies to 1.0 version (and inherits everything else form the global one)
    description "A simple 1.0 App"
    base_path "/"
  end
  
end
