
# Responses in Praxis

Sending a particular response from an action requires returning an instance of response object. A response object
is nothing else than a class derived from Praxis::Response. There are already many response classes defined in the system
that can be used, but new, application-specific responses can be added at will by creating new Praxis::Response derived classes.

Praxis automatically creates a DefaultResponse object for you, so that you don't need to worry about creating it within your
controller code if your action simply returns the common 200-type response.

Since it is really common for an action to simply worry about constructing the body of a request, Praxis also allows
a controller action return a simple string instead of a full response object. If that occurs, the system will simply
set that string as the body of the response object associated with the action.

Creating your own custom response involves the following pattern:

## Define your own Response class:

```ruby
  class MyTeaPotIsSteaming < Praxis::Response
    self.response_name = :tea_pot

    def handle
      # any custom logic that might required (or nothing is the initialization defaults are enough)
      @status  = 418
      @headers = { 'X-TeaPot' => 'MadeInJapan' }
      @body    = "I'm a tea pot, Jim"
    end
  end
```

The "handle" method will be invoked before sending the request to the client, in case there is particular
business logic that needs to be run to complete its information. If there's no "handle" method, nothing will be invoked.

As part of defining the response handling, you need to uniquely name it using the self.response_name function.
This name is what will be used to match against an existing response definition defined elsewhere. See XXX for details on
defining response specifications or using the set of pre-defined by the system. Here's a possible appropriate
one for our MyTeaPotIsSteaming class:

```ruby
Praxis::ApiDefinition.instance.register_response :tea_pot do
    description "I'm a teapot"
    status      418
    media_type  "application/json"
    headers     'X-TeaPot'
end
```

This definition is used to validate the response you create in your controllers. 
If your response object generates an output that does not match the corresponding response specification, the framework
will generate a response error communicating such a thing.


## Use your custom Response in your controllers:

If the result of the "index" action from your HelloWorld resource needs to return the response class above, you can
simply change the preset response for your action, change its contents (i.e. change a header) and return the body.
```ruby
  class HelloWorld
    def index(**params)
      self.response = MyTeaPotIsSteaming.new
      response.headers['Content-Type'] = 'application/json'
      # return response body
      'Tea is ready, come and get it!' 
      # or self.response.body = ''Tea is ready, come and get it!'; return self.response
    end
  end

```


## Access

Response classes will have access to attributes such as name, status, headers, body, request.
TODO: mediatype and/or multipart support in the near future
