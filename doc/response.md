
# Responses in Praxis
Every controller action in Praxis should return either a String or an instance of Praxis::Response.
Praxis automatically creates a default 200 response object for you, so that you don't need to worry about it if your action simply returns 200.

If your controller action returns a string, the string is used as the current response body.

If you need to have your own custom response, you can follow the next pattern:

## Describe you new response definition

```ruby
class HelloWorldDefinition < Praxis::ApiDefinition
  response :tea_pot do
    description "I'm a teapot"
    status      418
    media_type  "application/json"
    headers     'X-TeaPot'
  end
```

This definition is used to validate the response you create in your controllers. If there is a mismatch between the definition and your response, Praxis will raises an exception.

## Define your own Response class:

```ruby
  class MyTeaPotIsSteaming < Praxis::Response
    self.response_name = :tea_pot

    def handle
      # your custom logic if you need it, like:
      @status  = 418
      @headers = { 'X-TeaPot' => 'MadeInJapan' }
      @body    = "I'm a tea pot, Jim"
    end
  end

```

Make sure that MyTeaPotIsSteaming.response_name points to one of the existing response definitions or to the one you've defined above. There are some already predefined definitions (see lib/praxis/api_definition.rb): :default (200), :not_found (404), :validation (400), :internal_server_error (500).

MyTeaPotIsSteaming#handle method may have any custom logic you need to process the response.

## Use your custom Response in your controllers:

```ruby
  class HelloWorld
    def index(**params)
      self.response = MyTeaPotIsSteaming.new
      response.headers['Content-Type'] = 'application/json'
      # return response body
      'Tea is ready, come and get it!'
    end
  end

```
or

```ruby
  class HelloWorld
    def index(**params)
      my_headers = { 'X-TeaPot' => 'MadeInAntarctica' }
      my_body    = 'IceTea'
      # return our new custom response
      MyTeaPotIsSteaming.new(418, my_headers, my_body)
    end
  end

```

## Access

Following attributes are accessible on Response objects : name, status, headers, body, request.