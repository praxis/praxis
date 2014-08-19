Praxis::ApiDefinition.define do

  response_template :other_response do |media_type:|
    status 200
    media_type media_type
  end

  response_template :multipart do
    status 200
    media_type 'multipart/form-data'
  end

  response_template :bulk_response do |media_type:, parts: |
    status 200
    media_type 'multipart/form-data'

    parts[:media_type] ||= media_type if parts.kind_of? Hash
    parts(parts)
  end

  trait :authenticated do
    headers do
      header :host
    end
  end

end
