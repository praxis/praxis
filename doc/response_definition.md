# Response Definition Examples

Praxis allows you to define responses for your application. Examples on how to create a response
definition is shown below.

A valid response definition requires a status code to be set.
```ruby
ApiDefinition.define do |api|
  api.register_response :found do
    status 200
    description 'test description'
    headers {'X-Header' => 'value', 'Content-Type' => 'json'}
    media_type Praxis::MediaType
    multipart :optional do
      status 202
      headers 'X-Header: value'
    end
  end
end
```

## Response Headers

The header field in a response definition can take either a Hash, Array or a String object.
```ruby
ApiDefinition.define do |api|
  # header field set with a Hash
  api.register_esponse :found do
    status 200
    headers {'X-Header' => 'value', 'Content-Type' => 'json'}
  end

  # header field set with an Array
  api.register_response :found do
    status 200
    headers ['X-Header: value', 'Content-Type: json']
  end

  # header field set with a String
  api.register_response :found do
    status 200
    headers 'X-Header: value'
  end
end
```

## Response MediaTypes

A response media type can be either a String or MediaType object.
```ruby
# Praxis media_type
class ExampleMediaType < Praxis::MediaType; end

ApiDefinition.define do |api|
  # String media_type
  api.register_response :found do
    status 200
    media_type 'simple_media_type'
  end

  api.register_response :found do
    status 200
    media_type ExampleMediaType
  end
```

## Response Location

A response location can either be a String (absolute URI) or a Regex (relative URI).

```ruby
ApiDefinition.define do |api|
  api.register_response :redirection do
    status 302
    location 'http://www.example.com'
  end

  api.register_response :created do
    status 202
    location /api/
  end
```

## Multipart Responses

FIXME: this is now outdated.

A multipart response must be either `:always` or `:optional`.
```ruby
ApiDefinition.define do |api|
  api.register_response :found do
    status 200
    multipart :optional do
      status 202
      headers 'X-Header: value'
    end
  end
end
```
