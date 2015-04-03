---
layout: page
title: Handlers
---
The Praxis [`Request`](../requests/) and [`Response`](../responses/) classes encapsulate the gory
details of the HTTP protocol; specifically, they parse requests and generate responses so your
business logic can focus on the _content_ of messages, not the representation of that content.
Handlers are the "glue" that Praxis uses to parse request payloads and generate response bodies
so that your application sees requests as structured data (hashes and arrays), and responds with
the same.

Each handler understands a particular encoding mechanism: JSON, WWW-form, and so forth.
Praxis uses a heuristic to decide which handler is appropriate for a given HTTP body.

## Registration

Register new handlers at application startup time by invoking the `handler` DSL method inside
your app's config block. Each handler is identified by a short string name and implemented
using a Module or Class that responds to a few handler-interface methods.

{% highlight ruby %}
Praxis::Application.configure do |app|
  app.handler 'xml', Praxis::Handlers::XML
end
{% endhighlight %}

Praxis contains built-in handlers for JSON, form-encoding and XML, but only JSON and form-encoding
are registered automatically because XML adds some additional gem dependencies to the app. In
the example above, you would need to add `builder` and `nokogiri` to your Gemfile.

## Handler Selection

Praxis looks at the `content_type` of a request or response in order to determine the appropriate
handler. Specifically, it asks for the `handler_name` of the content type; this is a method of
`MediaTypeIdentifier` that applies a simple heuristic:
  - If the content type's suffix (e.g. `+json`, `+xml`) matches a handler name, use that handler
  - If the content's subtype (e.g. `json` in `application/json`) matches a handler name, use _that_ handler
  - Otherwise, assume `www-form-urlencoded` handler for requests and `json` for responses

This heuristic works because all of the structured-syntax suffixes defined in RFC6839 happen
to coincide exactly with the subtype of the corresponding Internet media type: `+json`,
`application/json` and `text/json` all imply the same thing about the _encoding_ of data, although
they have different implications about the _meaning_ of the data.

## Implementing a Custom Handler

Write your own handler by creating a Class that responds to three methods:

`initialize`
: check that your handler's dependencies are all satisfied and raise a helpful exception if not
`parse`
: given a `String`, decode into structured data and return structured data (`Hash` or `Array`)
`generate`
: given structured data, encode to String and return that string

Register your handler at app startup and handle with impunity!
