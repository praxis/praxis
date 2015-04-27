---
layout: page
title: Requests
---
The `Praxis::Request` class encapsulates all data aspects of an incoming web
request. It provides a means for retrieving basic properties such as HTTP verb,
path or API version information, as well as higher level curated objects such
as validated headers, params and payload structures.

## Verb

`request.verb` will return the request method, as a string. For example
`GET`.

## Version

`request.version` will return the requested API version associated with the
request. The value will always be a string, and if the request doesn't carry
any API version information, the string `n/a` will be returned. 

Underneath, Praxis will use the versioning scheme specified for the application,
and retrieve this value from the `X-Api-Version`, `api_version` parameter, or 
approriate capture from the path, as appropriate.


## Path

`request.path` will return the path component of the incoming request. For the
example `/blogs`. This method currently returns the value of the PATH_INFO key
in rack request environment.


## Params

You can get the coerced and validated parameters for the request using the
`request.params` method. It is common to define params using an
`Attributor::Struct` so the returned object will respond to method names
corresponding to the parameter definition of your action. Please see [Resource
Definitions and Actions](../resource-definitions/), for more information on
params.

Remember that params only contain values that appear in either URL captures or
query string parameters. No values coming from the request body would ever be
exposed through the `params` accessor.

## Headers

You can also obtain the complete set of headers for the given request using
`request.headers`. This will collect the headers from the requested action and
present them to you as a coerced and validated structure. Unlike the `params` 
object where attributes are accessible with dotted notation methods, the `headers` structure 
is presented as a hash, and therefore accessible through the "[]" notation.

Note that accessing header keys from the controller is case sensitive. Therefore, the string case 
used must always match the one described in your Resource Definition headers. For
example, let's assume that our API designer has defined the following action in some ResourceDefinition:

{% highlight ruby %}
action :create do
  routing { post '' }
  headers do
    key "Authorization", String, required: true
  end
end
{% endhighlight %}

In our controller we would need to check the headers using `request.headers['Authorization']`. Checking `request.headers['AuThOrIzAtIoN']` wouldn't yield any value.

Since the HTTP protocol defines headers are case insensitive, Praxis will allow loading 
incoming header names to the exact case that your definition describes. That
means that if an HTTP client send an "AuThOrIzAtIoN" header, Praxis will happily convert it to 
an "Authorization" key in your `request.headers` hash.

Please see [Resource Definitions and Actions](../resource-definitions/), for
more information on defining request headers in your action.

## Content Type

The `Content-Type` header is ubiquitous and has a well-known format (it's an Internet media type),
so requests have a special reader method for accessing their `content_type`. The reader method
returns a `MediaTypeIdentifier` object so you don't need to parse the header's value.

Refer to [Media Types](../media_types/) for more information about media type identifiers, and
[Handlers](../handlers/) to learn how Praxis uses the content type to parse a request's body
into structured data.

## Payload

`request.payload` will return any parameters that were passed through the
request body. The exposed payload values will be properly coerced and validated according 
to your payload spec in the corresponding action definition. Much like `request.params`, the 
`request.payload` object is an `Attributor::Struct` which responds to attribute names 
using dotted notation.

Note to advanced users: It is possible to override the default underlying structures for `params` 
and `payload` (which default to `Attributor::Struct`s), as well as `headers` (which defaults to `Hash.of(key:String)`) by providing a type rather than a simple block in the action definition. Please see
examples of that in the `bulk_create` action of the [Instances](https://github.com/rightscale/praxis/blob/master/spec/spec_app/design/resources/instances.rb) resource definition.
.

## Action

Request instances also provides an `action` method which you can use to
retrieve the full action definition object to which this request corresponds.
Access to the action definition object allows a certain amount of introspection
during a request.

Please see [Resource Definitions and Actions](../resource-definitions/), for
more information on actions.

## Other Low-Level Readers

There are a few low-level, read-only attributes that a request object also
exposes. It is unlikely that applications will need access to them, but Praxis
provides them just in case.

`request.env`
: provides the original rack `env` hash

`request.query`
: provides the parsed (but not coerced) collection of query string variables from the request
