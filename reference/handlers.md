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
using a Class that responds to a few handler-interface methods.

{% highlight ruby %}
Praxis::Application.configure do |app|
  app.handler 'xml', Praxis::Handlers::XML
end
{% endhighlight %}

### Built-in Handlers

The Praxis core contains handlers for plain text, JSON, form-encoding, and XML, but only plain text, JSON, and form-encoding
are registered automatically because XML has external dependencies.

To enable the XML handler, register it as shown in the example above, then add two gems to
your application's Gemfile.

{% highlight ruby %}
gem 'builder', '~> 3.2'
gem 'nokogiri', '~> 1.6'
{% endhighlight %}

#### XML Data Representation

Praxis' XML handler parses and generates documents that are compatible with Ruby On Rails'
`#to_xml` serialization mechanism. In brief:

* attributes and their values are represented as named tags with inner CDATA
* the `type` attribute indicates the data type of each value
* a special `type` value indicates an array of objects

This representation scheme does not have an XML DTD or schema because its tag names are open-ended,
but its predictable naming scheme allows you to define a schema that covers your application's
media types.

For more information, please refer to [ActiveSupport documentation](http://api.rubyonrails.org/classes/ActiveModel/Serializers/Xml.html#method-i-to_xml).

## Handler Selection

Praxis looks at the `content_type` of a request or response in order to determine the appropriate
handler. Specifically, it asks for the `handler_name` of the content type; this is a method of
`MediaTypeIdentifier` that applies a simple heuristic:

*  If the content type's suffix (e.g. `+json`, `+xml`) matches a handler name, use that handler
*  If the content's subtype (e.g. `json` in `application/json`) matches a handler name, use _that_ handler
*  Otherwise, assume `www-form-urlencoded` handler for requests and `json` for responses

This heuristic works because all of the structured-syntax suffixes defined in RFC6839 happen
to coincide exactly with the subtype of the corresponding Internet media type: `+json`,
`application/json` and `text/json` all imply the same thing about the _encoding_ of data, although
they have different implications about the _meaning_ of the data.

## Implementing a Custom Handler

Write your own handler by creating a Class that responds to three methods:

`#initialize`
: Check that your handler's dependencies are all satisfied and raise a helpful exception if not.

`#parse`
: Given a `String`, decode into structured data and return structured data (`Hash` or `Array`).

`#generate`
: Given structured data, encode to String and return that string.

Use the [XML handler](https://github.com/rightscale/praxis/blob/master/lib/praxis/handlers/xml.rb)
as an implementation guide. When you're finished implementing, register your handler at app startup
and handle with impunity!
