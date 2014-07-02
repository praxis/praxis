
# Responses in Praxis
Every controller action in Praxis should return either a String or an instance of Praxis::Response.
Praxis automatically creates a default 200 response object for you, so that you don't need to worry about it if your action simply returns 200.

If your controller action returns a string, the string is used as the default response body.

If you need to have your own custom response, you can follow the next pattern:

## Define your own Response class:

```ruby
  class MyTestAppIsDead < Praxis::Response
    self.response_name = :internal_server_error

    def handle
      # your custom logic if you need it, like:
      @status  = 500
      @headers = {}
      @body    = "I'm dead, Jim"
    end
  end

```

Make sure that MyTestAppIsDead.response_name points to one of the existing response definitions. There are some already predefined definitions (see lib/praxis/api_definition.rb): :default (200), :not_found (404), :validation (400), :internal_server_error (500).

MyTestAppIsDead#handle method may have any custom logic you need to process the response.

## Use your custom Response in your controllers:

```ruby
  class HelloWorld
    def index(**params)
      response = MyTestAppIsDead.new
      response.headers['Content-Type'] = 'application/json'
      response.body = 'Goodbye, world!'
      response
    end
  end

```
or

```ruby
  class HelloWorld
    def index(**params)
      my_headers = { 'X-Foo' => 'Bar' }
      my_body    = 'MyBody'
      MyTestAppIsDead.new(501, my_headers, my_body)
    end
  end

```

## Access

Following attributes are accessible on Response objects : name, status, headers, body, request.
