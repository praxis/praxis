---
layout: page
title: Multipart Encoding
---

Praxis has built-in support for handling "multipart/form-data" (link to RFC?) encoded requests and responses, in the form of the `Praxis::Types::MultipartArray` type, and the `Praxis::Responses::MultipartOk` response.


## Praxis::Types::MultipartArray

The `MultipartArray` type is an `Attributor::Collection` of `Praxis::MultipartPart` members that allows you to specify how to handle each of the existing parts of a multipart request or response body.


### Definition

Describing the body of a `MultipartArray` consists of defining shape of it parts. There are three ways to define the parts:
  
  * One can loosely define all the parts have the same payload and name type (which defaults to `String` and implies no restrictions or coercions should be applied).
  * One can also define the type of a payload (and headers) for a specific part by name  
  * Or, one can define the expected payload type (and headers) for a group of parts with names matching a regular expression.


Here's an example where all of the part names are of type `String` that all have payloads of type `Hash`:
{% highlight ruby %}
class SimpleExample < Praxis::Types::MultipartArray
  name_type String
  payload_type Hash
end
{% endhighlight %}


Here's one that that defines specific named parts and uses a regular expression to define a group of related parts:
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

Parts can also be defined to contain files (and match a filename). To do that you can pass the `filename: true` option when defining the part (or equivalently use the `file` method instead for syntactic sugar). Use the `filename` DSL inside the part definition to express any expected string or pattern for it.

Also, part names are allowed to be repeated. To enable that use the `multiple: true` option in a part so that it can appear as an array of parts sharing the same name.

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


Here is a more complete (and complex) example of defining a multipart type that defines several parts in different ways for illustration purposes:

{% highlight ruby %}
class ImageUpload < Praxis::Types::MultipartArray

  # Image author, loaded (and validated) as pre-defined Author type  
  part 'author', Author, 
    required: true, 
    description: 'Authorship information'  
  
  # Set of tags, as strings. May be specified more than once.
  part 'tags', String
    multiple: true, 
    description: 'Category name. May be given multiple times'

  # Any part whose name ends in '_at' should be a DateTime
  part /_at$/, description: 'Timestamp information for the set of files' do
    payload DateTime
  end

  # The parser will save uploaded file as a Ruby Tempfile.
  # Note: This maps to the Attributor::Tempfile type.
  part 'image', Tempfile, 
    required: true
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


### Using MulripartArray Instances


To retrieve specific part(s) by name from an instance of a `MultipartArray`, use `part(name)`. 
This returns a singular part (i.e., defined without `multiple: true`) part as a `MultipartPart` instance, and multiple parts (even if only one instance was provided) as an `Array` of `MultipartPart` instances.

You may also use the `MultipartArray` as an array of all of the `MultipartPart` instances with all of the standard Ruby `Array` and `Enumerable` methods.

To add one, or more, `MultipartPart` instances to the array, use `push(part)` or `push(*parts)`. This will validate the part names and coerce any headers and payload as applicable.

Individual `MultipartPart` instances have the following methods:

  * `payload`: the part body data
  * `headers`: hash of headers
  * `name`: part name
  * `filename`: filename, if applicable


## Returning Multipart Responses

### Responses::MultipartOk

The `MultipartOk` response is used to easily return a  `MultipartArray` body. It takes care of properly encoding the body as "multipart/form-data", with a proper "Content-Type" header specifying the boundary of each part. The response is registered as `:multipart_ok`. 

Each part will also be dumped according to its "Content-Type" header, using any applicable handlers registered with Praxis. See [`Handlers`](../requests/) for more details on how to define and register custom handlers.

You can specify the exact form of a `:multipart_ok` response, either for documentation purposes or for response body validation, by passing predefined type to `response :multipart_ok` in your action definition or by using the generic `Praxis::Types::MultipartArray` and providing a block to further define it.

For example, to use declare that a response should match the `ImageUpload` type above, you would do: `response :multipart_ok, ImageUpload`. Alternately, you could do something like the following:

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





