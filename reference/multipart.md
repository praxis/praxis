---
layout: page
title: Multipart Encoding
---

Praxis has built-in support for handling "multipart/form-data" (link to RFC?) encoded requests and responses, in the form of the `Praxis::Types::MultipartArray` type, and the `Praxis::Responses::MultipartOk` response.


## Praxis::Types::MultipartArray

The `MultipartArray` type is an `Attributor::Collection` of `Praxis::MultipartPart` members that allows you to specify the handling of each part of a multipart request or response body.

### Definition

* `part 'name'`
* `part /name/`
* `part 'email', multiple: true`

* defining parts that are files:
  * simple: `part 'file', filename: true`
  * simpler: `file 'file'`
  * with filename string validation:
    * `file 'file' { filename values: ['thumb.jpg'] }`
    * `file 'file' { filename regex: /^img-/ }`
  * with a filename of type other than String
    * `file 'daily' { filename DateTime }`

Example: 

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


### Use


To retrieve specific part(s) by name from an instance of a `MultipartArray`, use `part(name)`. 
This returns a singular part (i.e., defined without `multiple: true`) part as a `MultipartPart` instances, and multiple parts (even if only one instance was provided) as an `Array` of `MultipartPart` instances.

You may also use the `MultipartArray` as an array of all of the `MultipartPart` instances.

Use `push(part)` or `push(*parts)` to add one, or more, `MultipartPart`s to the array. This will validate the part names and coerce any headers and payload as applicable.

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





