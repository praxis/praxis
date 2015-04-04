---
layout: page
title: Using Responses
---
To send a response from an action, returning an instance of a response class.
A response class is just a class that extends Praxis::Response. Praxis comes
with
[many](https://github.com/rightscale/praxis/blob/master/lib/praxis/responses/http.rb)
common response classes ready to use, but you can add new application-specific
responses by extending Praxis::Response.

See [Returning a Response](../controllers/) from the Controllers section to
read about other ways to handle responses from controllers.

## Response Body

Many responses have a body: some useful content that is sent back to the user agent.
Provide a body by calling the `body=` writer of your response. If your response has
a body, then you should also set its `content_type=` so the user agent will know how
to handle your data.

If you provide a String response body, Praxis will respond verbatim with the body and
content-type header you have provided. If you provide structured data -- a Hash
or an Array -- Praxis will analyze your response's `content_type` and encode your
data using a suitable handler (or JSON if no specific handler seems appropriate).
See [Handlers](../handlers/) to learn how to customize encoding.

{% highlight ruby %}
response.content_type = 'application/vnd.acme.greeting'
response.body = {hi: 'mom'}

# The user agent will receive a response like so:
#   Content-Type: application/vnd.acme.greeting+json
#
#   {"hi":"mom"}
{% endhighlight %}

Response encoding is performed by the `encode!` method of the Response base class;
custom responses may alter or supplant this behavior.

## Creating Custom Response Classes

To create a custom response class:

- create a class that extends `Praxis::Response`
- set the response name. This links your class to a response definition, the
  API design object.
- optionally set the class-level `status` value. If you don't do it here, you
  will need to set it in an initializer

A `Response` class may define the following methods, which will be invoked
before sending the request to the client:

`handle`
: executes any business logic that needs to be done to complete the response
  data.

`format!`
: constructs the format of the response object. For example, it could transform
  the body object into a hash with appropriate attributes. The default `format!`
  behavior is to not modify the body.

`encode!`
: encodes the formatted contents of the request. For example, it could
  look at some aspect of the request to figure out how to encode the
  response.

Here is an example of a response class:

{% highlight ruby %}
# As specified in RFC 2324 (seriously; look it up!)
class ImATeapot < Praxis::Response
  self.response_name = :tea_pot
  self.status = 418

  def handle
    # any custom logic that might required (or nothing if the initialization defaults are enough)
    headers['X-TeaPot'] = 'MadeInJapan'
  end
end
{% endhighlight %}

*Note:* Each of the response classes you create in the runtime part of your application will need a corresponding response template defined in the design area that shares the same name. Make sure you use the `register_response` DSL that the ApiDefinition class provides. In this case, we would need to register a template named `:tea_pot`, which must match a status code of 418 and a 'X-TeaPot' header of value 'MadeInJapan'. See [Response Definitions](../response-definitions/) for more information on how to do that. If you don't register a template for each of your classes, you will not be able to refer to them in your `response` stanzas of your actions in your ResourceDefinitions.


## Using Custom Response in Your Controller

When instantiating a new instance of your Praxis::Response derived class, you
can pass along named parameters for `status`, `headers`, and `body`. For
example:

{% highlight ruby %}
class HelloWorld
  def index(**params)
    self.response = MyTeaPotIsSteaming.new(status: 201, body: 'my new content')
    ...
  end
end
{% endhighlight %}

For more information on returning responses from controllers, see [Returning a
Response](../controllers/#returning-a-response) in the controllers section.


## Generating Multipart Responses

Praxis also provodes support for generating multipart responses. In
particular, Praxis provides:

- an `add_parts` accessor in `Praxis::Response` to add parts to be returned in
  a response.
- a `parts` accessor in `Praxis::Response` to list the parts contained in a
  response.
- a `Praxis::MultipartPart` class to represent and format individual parts

The following multipart response contains two parts named 'part1' and 'part2'.
Both use the 'text/plain' Content-Type:

{% highlight ruby %}
response = Responses::Multipart.new(status:200, media_type: 'multipart/form-data')
plain_headers = {'Content-Type' => 'text/plain'}

part1 = Praxis::MultipartPart.new("this is part 1", plain_headers)
response.add_part("part1", part1)

part2 = Praxis::MultipartPart.new("this is part 2", plain_headers)
response.add_part("part2", part2)
{% endhighlight %}

You may want to return a corresponding response part for every received part of
a multipart request. The following `bulk_create` action returns a multipart
response with an individual "created" part for every request part it receives.
For a multipart request, the `payload` method returns a `Praxis::Multipart`
type which supports the `.each` method to loop over the individual parts.

{% highlight ruby %}
def bulk_create
  self.response = BulkResponse.new #defauling to status:200 and 'multipart/form-data'

  request.payload.each do |part_name, part|
    headers = {
      'Status' => '201',
      'Location' => "/resource/#{part_name}"
    }
    part_body = nil # 201, has no body
    part = Praxis::MultipartPart.new(part_body, headers)

    response.add_part(part_name, part)
  end

  response
end
{% endhighlight %}
