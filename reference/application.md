---
layout: page
title: Application
---


### Uncaught Exceptions

Handling of uncaught exceptions is done by the error handler registered with `Appication#error_handler`. All applications are pre-configured to use a simple handler that wraps any exception in an `InternalServerError` response.

This behavior may be customized by registering an error handler with the application like this:

{% highlight ruby %}
Praxis::Application.configure do |application|
  application.error_handler = MyErrorHandler.new
end
{% endhighlight %}

The error handler must implement a `handle!(request, error)` method, where `request` is the current `Request` instance being processed, and `error` is the exception in question. The return value is sent back to the client.

### Rack Middleware

Praxis supports registering Rack middleware to run _internally_ during handling with `Application#middleware`. The syntax is analogous to the `use` directive in `Rack::Builder` (and in fact does that internally). This is in addition to configuring middleware through standard Rack means such as a `config.ru` file, and is entirely optional.

The primary distinction being that the effects of middleware run through `Application#middleware` *will* be included in `Stats` and `Notifications` timings such as the "rack.request.all" notification.

For example, to use middleware named `MyMiddleware` you would put the following in your `config/environment.rb`:

{% highlight ruby %}
Praxis::Application.configure do |application|
  application.middleware MyMiddleware
end
{% endhighlight %}
