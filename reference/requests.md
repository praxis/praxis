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
any API version information, the string `n/a` will be returned. Underneath,
Praxis will retrieve this value directly come from either the
`HTTP_X_API_VERSION` header if present or from the `api_version` parameter.

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
present them to you as a coerced and validated structure.

Please see [Resource Definitions and Actions](../resource-definitions/), for
more information on request headers.

## Payload

`request.payload` will return any parameters that were passed through the
request body. Much like params and headers, the exposed payload values will be
properly coerced and validated according to your payload spec in the
corresponding action definition. The `request.payload` object is typically an
`Attributor::Struct` which responds to attribute names using dotted notation
(unless you have defined the payload block using a different type).

Please see [Resource Definitions and Actions](../resource-definitions/), for
more information on action payload.

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
