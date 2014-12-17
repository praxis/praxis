---
layout: page
title: Application
---


### Uncaught Exceptions

Handling of uncaught exceptions is done by the error handler registered with `Appication#error_handler`. All applications are pre-configured to use a simple handler that wraps any exception in an `InternalServerError` response.

This behavior may be customized by registering an error handler with the application like this:
```ruby
Praxis::Application.configure do |application|
  application.error_handler = MyErrorHandler.new
end
```

The error handler must implement a `handle!(request, error)` method, where `request` is the current `Request` instance being processed, and `error` is the exception in question. The return value is sent back to the client.

### Rack Middleware

Praxis supports registering Rack middleware to run as part of request handling with `Application#middleware`. The syntax is analogous to the `use` directive in `Rack::Builder` (and in fact does that internally).

For example, to use middleware named `MyMiddleware` you would put the following in your `config/environment.rb`:
```ruby
Praxis::Application.configure do |application|
  application.middleware MyMiddleware
end
```

This may be used in addition to, or in replacement of, configuring middleware in an application's `config.ru`.
