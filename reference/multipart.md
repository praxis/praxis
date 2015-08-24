---
layout: page
title: Multipart Encoding
---

Praxis has built-in support for handling "multipart/form-data" (link to RFC?) encoded requests and responses.
The support is provided with the `Praxis::Types::MultipartArray` type, and the `Praxis::Responses::MultipartOk` response.

## Praxis::Types::MultipartArray

The `MultipartArray` type is an `Attributor::Collection` of `Praxis::MultipartPart` members that
allows you to describe each part of a multipart request or response body.

### Definition

There are three different ways that the members of a `MultipartArray` can be defined:
  
  * Using `name_type` and `payload_type` to define multipart content where all parts are identical.
  * Using `part` to define the content of specific part by name
  * Using `part` together with a regular expression to define the content of parts whose names match the regular expression.

Here's an example where all the part names are of type `String` and all the part payloads are of type `Hash`:
{% highlight ruby %}
class SimpleExample < Praxis::Types::MultipartArray
  name_type String
  payload_type Hash
end
{% endhighlight %}
Using `String` as the type name means that Praxis will not perform any validation or coercion. Also
both `name_type` and `payload_type `are optional and not specifying one is equivalent to using the
`String` type.

Here's another example that defines specific named parts and uses a regular expression to define a
group of related parts:
{% highlight ruby %}
class NamedPartsExample < Praxis::Types::MultipartArray
  # a part named "title" with default String payload
  part 'title'

  # a part named "uri" with a URI payload
  part 'uri', URI

  # a part named "contents" 
  part 'contents' do
    # that should have a Content-Type header of "application/json"
    header 'Content-Type', 'application/json'

    # and be loaded as a Hash
    payload Hash
   end

  # any parts with names ending in "_at" are DateTimes
  part /_at$/, DateTime
end
{% endhighlight %}

Parts can also be defined to contain files using the `filename` option with a value of `true`, or the `filename` directive in the `part` DSL which defines the attribute that should be used to validate the filename value.

The `file` method can be used in place of `part` to define a part that contains a file.

Multiple parts may need to have the same name, this can be achieved by providing the `multiple: true`
option when defining the part. When this option is set the corresponding part becomes an array.

Here are some examples for defining file parts:
{% highlight ruby %}
class FilePartExamples < Praxis::Types::MultipartArray
  # a part named "thumbnail", that should have a filename
  part 'thumbnail', filename: true

  # a part named "image", that should also have a filename
  file 'image'

  # any number of parts named "files"
  part 'files', multiple: true do
    # with names containing "img"
    filename /img/

    # and a payload loaded as a Tempfile
    payload Attributor::Tempfile
  end    
end
{% endhighlight %}

Here is a more complete (and complex) example of defining a multipart type that defines several
parts in different ways for illustration purposes:

{% highlight ruby %}
class ImageUpload < Praxis::Types::MultipartArray

  # Image author, loaded (and validated) as pre-defined Author type  
  part 'author', Author, 
    required: true, 
    description: 'Authorship information'  
  
  # Set of tags, as strings. May be specified more than once.
  part 'tags', String,
    multiple: true, 
    description: 'Category name. May be given multiple times'

  # Any part whose name ends in '_at' should be a DateTime
  part /_at$/, description: 'Timestamp information for the set of files' do
    payload DateTime
  end

  # The parser will save uploaded file as a Ruby Tempfile.
  # Note: This maps to the Attributor::Tempfile type.
  part 'image', Tempfile, 
    required: true,
    filename: true, 
    description: 'Image to upload'

  # Ensure the incoming thumbnail is a jpeg with proper filename'
  file 'thumbnail', description: 'Image thumbnail, must be jpeg' do
    header 'Content-Type', 'image/jpeg'
    payload Attributor::Tempfile
    filename values: ['thumb.jpg']
  end

end
{% endhighlight %}

### Using MultipartArray Instances

Use `part(name)` to retrieve a specific part by name from an instance of `MultipartArray`.
This returns a `MultipartPart` instance or an array of such instances in the case of parts defined
with `multiple: true` (even if only one instance was provided).

You may also use the `MultipartArray` as an array of all of the `MultipartPart` instances with all
of the standard Ruby `Array` and `Enumerable` methods.

To add one, or more, `MultipartPart` instances to the array, use `push(part)` or `push(*parts)`.
This will validate the part names and coerce any headers and payload as applicable.

`MultipartPart` instances have the following methods:

  * `payload`: the part body data
  * `headers`: hash of headers
  * `name`: part name
  * `filename`: filename, if applicable


## Returning Multipart Responses

### Responses::MultipartOk

The `MultipartOk` response is used to easily return a `MultipartArray` body.
It takes care of properly encoding the body as "multipart/form-data", with a proper "Content-Type"
header specifying the boundary of each part. The response is registered as `:multipart_ok`.

Each part will also be dumped according to its "Content-Type" header, using any applicable handlers
registered with Praxis. See [`Handlers`](../requests/) for more details on how to define and
register custom handlers.

You can specify the exact form of a `:multipart_ok` response - either for documentation purposes or
for response body validation - by passing a predefined type to `response :multipart_ok` in your
action definition or by using the generic `Praxis::Types::MultipartArray` and providing a block to
further define it.

For example, to declare that a response should match the `ImageUpload` type above, you would do:
`response :multipart_ok, ImageUpload`. Alternately, you could do something like the following:

{% highlight ruby %}
response :multipart_ok, Praxis::Types::MultipartArray do
  part 'name', String
  part 'timestamps' do
    attribute 'created_at', DateTime
    attribute 'updated_at', DateTime
  end
  part 'address', Address
end
{% endhighlight %}
