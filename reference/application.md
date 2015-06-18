---
layout: page
title: Application
---


### Uncaught Exceptions

Handling of uncaught exceptions is done by the error handler registered with `Application#error_handler`. All applications are pre-configured to use a simple handler that wraps any exception in an `InternalServerError` response.

This behavior may be customized by registering an error handler with the application like this:

{% highlight ruby %}
Praxis::Application.configure do |application|
  application.error_handler = MyErrorHandler.new
end
{% endhighlight %}

The error handler must implement a `handle!(request, error)` method, where `request` is the current `Request` instance being processed, and `error` is the exception in question. The return value is sent back to the client.

### Formatting Validation Responses

Any validation errors encountered in the flow of the request will be processed by the registered `validation_handler` in the Application. All applications are pre-configured to use a handler that generates validation responses using the `Responses::ValidationError` class.

This default behavior, however, may be customized by registering your own validation handler like this:

{% highlight ruby %}
Praxis::Application.configure do |application|
  application.validation_handler = MyValidationHandler.new
end
{% endhighlight %}

The validation handler must implement a `handle!(summary:, request:, stage:, errors: nil, exception: nil, **opts)` method where:

* `summary` is a string containing a short description of the validation error
* `request` is the current `Request` instance being processed. One can get to the `action` and other interesting values from it.
* `stage` is a symbol denoting where in the request flow the validation error occurred. The possible received values are:
  * `:params_and_headers`: if it occurred validating the parameters or headers.
  * `:payload`: if it occurred validating the payload.
  * `:response`: if it occurred validating the response. This can only occur if the `validate_responses` configuration is enabled.
* `errors` is an array of the errors as returned by the underlying type validations performed. The default types for headers, params and payload will return individual error message containing a string with the details of the encountered error. If you are using custom payload types, however, they could return different data in each of the individual error messages.
* `exception` is the exception in question.

The return valid from the `handle!` must be a Praxis response, which will be directly returned to the client.

### Rack Middleware

Praxis supports registering Rack middleware to run _internally_ during handling with `Application#middleware`. The syntax is analogous to the `use` directive in `Rack::Builder` (and in fact does that internally). This is in addition to configuring middleware through standard Rack means such as a `config.ru` file, and is entirely optional.

The primary distinction being that the effects of middleware run through `Application#middleware` *will* be included in `Stats` and `Notifications` timings such as the "rack.request.all" notification.

For example, to use middleware named `MyMiddleware` you would put the following in your `config/environment.rb`:

{% highlight ruby %}
Praxis::Application.configure do |application|
  application.middleware MyMiddleware
end
{% endhighlight %}
