# Response Definition Examples

Praxis allows you to define responses for your application. Examples on how to create a response
definition is shown below.

A valid response definition requires a status code to be set.
```ruby
response :found do
  status 200
  description 'test description'
  headers {'X-Header' => 'value', 'Content-Type' => 'json'}
  media_type Praxis::MediaType
  group :default
  multipart :optional do
  	status 202
  	headers 'X-Header: value'
  end
end
```

## Response Headers

The header field in a response definition can take either a Hash, Array or a String object.
```ruby
# header field set with a Hash
response :found do
  status 200
  headers {'X-Header' => 'value', 'Content-Type' => 'json'}
end

# header field set with an Array
response :found do
  status 200
  headers ['X-Header: value', 'Content-Type: json']
end

# header field set with a String
response :found do
  status 200
  headers 'X-Header: value'
end
```

## Response MediaTypes

A response media type can be either a String or MediaType object.
```ruby
# String media_type
response :found do
  status 200
  media_type 'simple_media_type'
end

# Praxis media_type
class ExampleMediaType < Praxis::MediaType; end

response :found do
  status 200
  media_type ExampleMediaType
end
```

## Response Location

A response location can either be a String (absolute URI) or a Regex (relative URI).

```ruby
response :redirection do
  status 302
  location 'http://www.example.com'
end

response :created do
  status 202
  location /api/
end
```

## Multipart Responses

A multipart response must be either `:always` or `:optional`.
```ruby
response :found do
  status 200
  multipart :optional do
  	status 202
  	headers 'X-Header: value'
  end
end
```

## Grouping Responses

Multiple responses can be grouped together using the `group` attribute in the response definition. By default, the response are grouped under `:default` group.

```ruby
response :created do
  status 202
  description 'test description'
  group :found
end

response :updated do
  status 202
  description 'test description'
  group :found
end
```