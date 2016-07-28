---
layout: page
title: Getting Started
---
So you're new to Praxis, you've read some of the cool stuff that it can do and
you're ready to give it a try.

Great! Let's get started by creating an API resource from scratch with
documentation, and querying our running API server from the command line. We'll
be making a simple Post resource for a blog application, but before we do that,
we need to set up our app.

## Setting Up a Praxis App

Once Praxis is installed, the easiest way to get up and running is to use the
Praxis app generator to create a sample app. In order to use the app generator,
you'll need to install the Praxis gem.

{% highlight bash %}
$ gem install praxis
# or if your GEM_HOME is system-wide
$ sudo gem install praxis
$ praxis example blog
      create  blog/app
      create  blog/design
      create  blog/lib
      create  blog/spec
      create  blog/config/environment.rb
      create  blog/Gemfile
      create  blog/Rakefile
      create  blog/config.ru
      create  blog/design/api.rb
      create  blog/design/resources/hello.rb
      create  blog/design/media_types/hello.rb
      create  blog/app/controllers/hello.rb
{% endhighlight %}

`bundle install` to install the app's gem dependencies:

{% highlight bash %}
$ cd blog/
$ bundle install
...
Your bundle is complete!
{% endhighlight %}

You already have a basic Praxis application, that includes a sample resource
called hello! Now you can look at the routes it exposes:

{% highlight bash %}
$ bundle exec rake praxis:routes
+-------------------------------------------------------------------------------------------------------+
| version |      path      | verb |        resource         | action | implementation  | name | primary |
+-------------------------------------------------------------------------------------------------------+
| 1.0     | /api/hello     | GET  | V1::ApiResources::Hello | index  | V1::Hello#index |      | yes     |
| 1.0     | /api/hello/:id | GET  | V1::ApiResources::Hello | show   | V1::Hello#show  |      | yes     |
+-------------------------------------------------------------------------------------------------------+
{% endhighlight %}

Use rackup to start the app:

{% highlight bash %}
$ bundle exec rackup -p 8888
[2014-08-13 10:11:45] INFO  WEBrick 1.3.1
[2014-08-13 10:11:45] INFO  ruby 2.1.2 (2014-05-08) [x86_64-linux]
[2014-08-13 10:11:45] INFO  WEBrick::HTTPServer#start: pid=18468 port=8888
{% endhighlight %}

Now you can hit one of the app's routes to see it working:

{% highlight bash %}
$ curl -i http://localhost:8888/api/hello -H 'X-Api-Version: 1.0' -X GET

HTTP/1.1 200 OK
Content-Type: application/json
Transfer-Encoding: chunked
Server: WEBrick/1.3.1 (Ruby/2.1.2/2014-05-08)
Date: Mon, 28 Jul 2014 21:45:35 GMT
Content-Length: 107
Connection: Keep-Alive

["Hello world!","Привет мир!","Hola mundo!","你好世界!","こんにちは世界！"]
{% endhighlight %}

Congratulations, you've just received a response from your first Praxis app!
Try these other commands, and see what you get:

{% highlight bash %}
$ curl -i http://localhost:8888/api/hello/2 -H 'X-Api-Version: 1.0' -X GET  # Show
$ curl -i http://localhost:8888/api/hello/2 -H 'X-Api-Version: 2.0' -X GET  # NotFound Error
{% endhighlight %}

Once you've finished testing the `Hello` controller, type `CTRL+c` in the
terminal where you started the server earlier to kill your Praxis app.

Now it's time to get your hands dirty and see how to use Praxis to build
services with full-featured REST APIs.

### Other Dependencies

Praxis uses the [randexp](https://github.com/benburkert/randexp) library to generate examples given regular expressions, which expects to find a word list (dictionary) in one of three common locations: ```/usr/share/dict/words``` or ```/usr/dict/words```, or  ```~/.dict/words```.

This should be present by default in OS X as well as most (but not all) Linux distributions. If you receive an error like "Words file not found. Check if it is installed..." then you need to install a package that provides one.

For apt-based distributions, you can install one with the ```wamerican``` package (see the relevant [debian](https://packages.debian.org/search?keywords=wamerican) or [ubuntu](http://packages.ubuntu.com/search?keywords=wamerican) pages for more information or alternatives).

For yum-based distributions, you need the the ```words``` package.


## Design vs Implementation

One of the goals of the Praxis framework is to allow designers to define a
complete API specification without writing a single line of business logic.
When creating a Praxis application, design and implementation should be treated
as separate, independent phases.

The output of the design phase is a full specification of the API. This
includes API versions, resources, actions, routes, parameter validation, and
definitions of the media types returned by every action. You can view a
human-readable version of the API specification using the API browser included
with Praxis, but the specification is also available in JSON format.

Praxis differentiates itself from other frameworks in that everything defined
in the design phase is actual code that will be enforced when the app runs. In
other words, the API specification is intimately tied to its implementation.
Praxis guarantees that link is never broken, so the documentation is always
correct with respect to API behavior. A forgetful developer or documenter
cannot cause the documentation to become stale.

The second phase of building an API consists of actually implementing the
business logic behind each of the controller actions. However, this excludes
all the boilerplate code for validating and coercing incoming parameters
because the framework takes care of that based on the specification you've
already defined in the specification.

## Design Phase

To build a Praxis app, start by designing the API. This example API will expose
a ```Post``` resource and two simple actions: ```show``` and ```create```.

### Creating a ResourceDefinition

To expose an API resource in Praxis, create its _resource definition_ which is
just a Ruby class that includes ```Praxis::ResourceDefinition```:

{% highlight ruby %}
# design/v1/resources/posts.rb
module V1
  module Resources
    class Posts
      include Praxis::ResourceDefinition
      version "1.0"

      action :show do
      end

      action :create do
      end
    end
  end
end
{% endhighlight %}

Use the `version` method to define which API version this resource supports.
Define ```show``` and ```create``` actions by calling the ```action``` method.

Note: We wrapped the `Posts` class here in the `V1` and `ResourceDefinitions`
modules to better organize our code. This also allows us to create other
versions of the Posts resource later.

Now you have two actions defined, but Praxis needs you to fill in the interface
specification before you can use them. Take the following example:

{% highlight ruby %}
# design/v1/resources/posts.rb
module V1
  module Resources
    class Posts
      include Praxis::ResourceDefinition

      version '1.0'
      media_type 'application/json'

      action :show do
        routing do
          get '/:id'
        end

        params do
          attribute :id, Integer,
            required: true,
            min: 0
          attribute :allow_deleted, Attributor::Boolean,
            default: false,
            description: "Allow returning deleted Posts"
        end

        response :ok
      end

      action :create do
        routing do
          post ''
        end

        payload do
          attribute :title, String,
            required: true,
            description: "Title for the Post"
          attribute :content, String,
            description: "Post body contents"
        end

        response :created
      end
    end
  end
end
{% endhighlight %}

In the :show action definition, use the ```routing``` DSL block to specify that
you want to respond to the ```GET``` HTTP method for requests to the ```/posts/:id```
URL path. For example, requests such as ```GET /posts/1``` will be routed to
our ```show``` action. Furthermore, the ```:id``` attribute in the URL is
of type ```Integer``` and is marked as required. The action also accepts an
optional ```:allow_deleted``` parameter, which could allow clients to indicate that
they wish to retrieve posts even if they have been deleted. By making
```:allow_deleted``` an ```Attributor::Boolean``` and setting its default value
to ```false```, you can avoid worrying about these details during
implementation and improve the clarity of the generated documentation.

Use the ```routing``` DSL block again to mount the ```create``` action to the
```POST``` HTTP verb ```/``` path. This action has no required or optional URL
parameters, but it does accept a payload with a required ```title``` attribute,
and an optional ```content``` attribute. Both attributes are of type
```String```.

Note: You might have noticed that the ```show``` action's routing block uses
`get '/:id'` rather than ```get '/posts/:id'```. Very observant! This is
because every ```ResourceDefinition``` class has a default prefix that applies
to all of its actions.  The default prefix for a resource definition is the
snake-cased name of its class (e.g., ```Posts``` becomes ```/posts``` and
```UserComments``` becomes ```/user_comments```). You may specify an
alternative prefix by calling the ```prefix``` method with the prefix you want
to use. See the documentation on [Resource Definitions and
Actions](/reference/resource-definitions) for more information.

{% highlight ruby %}
# design/v1/resources/posts.rb
module V1
  module Resources
    class Posts
      include Praxis::ResourceDefinition

      version '1.0'

      routing do
        prefix '/my_posts'
      end
    end
  end
end
{% endhighlight %}

### Displaying routes

Check the application's routing table to make sure the Posts resource appears:

{% highlight bash %}
$ bundle exec rake praxis:routes
+-----------------------------------------------------------------------------------------------------------------+
| version |      path      | verb |        resource         | action |      implementation       | name | primary |
+-----------------------------------------------------------------------------------------------------------------+
| 1.0     | /api/hello     | GET  | V1::ApiResources::Hello | index  | V1::Hello#index           |      | yes     |
| 1.0     | /api/hello/:id | GET  | V1::ApiResources::Hello | show   | V1::Hello#show            |      | yes     |
| 1.0     | /my_posts/:id  | GET  | V1::Resources::Posts    | show   | n/a                       |      | yes     |
| 1.0     | /my_posts      | POST | V1::Resources::Posts    | create | n/a                       |      | yes     |
+-----------------------------------------------------------------------------------------------------------------+
{% endhighlight %}

There they are! We can now see a show and a create action for the Posts
resource. The observant reader might have also noticed that the implementation
column tells you there are currently no implementations of these actions.

### Building API documentation

Now you can see that Praxis knows about your Posts resource routes, but how can
you start reviewing the interface details for these actions? Ask Praxis to
generate documentation for you:

{% highlight bash %}
$ bundle exec rake praxis:docs:generate
{% endhighlight %}

This generates a series of JSON files with the full specification of the API we
have defined thus far. This JSON specification is readily consumable by dynamic
client generators or converters to other existing formats.

Thankfully, Praxis can generate the same documentation in a more human-friendly
format:

{% highlight bash %}
$ bundle exec rake praxis:docs:preview
...
Running "connect:livereload" (connect) task
Started connect web server on http://0.0.0.0:9090

Running "watch" task
Waiting...
{% endhighlight %}

which should open up a new browser page for you, pointing to the documentation browser (typically at `http://localhost:9090`). This task will automatically detect any changes to your design objects, and redisplay the results the browser for you. It is common to have the browser and the API design editor side by side, to see the changes as new things are added or edited.

If you have the praxis gem installed in the system, you can directly use its executable. In this case, typing `praxis docs` would be equivalent to (`bundle exec rake praxis:docs:preview`). See `praxis --help` (and `rake -T`) for more commands and information.

For our example, the doc browser should show you something like this, which incudes the already existing
definition of the sample 'hello' app, plus your ```Posts``` resource, including
both actions and their URLs, parameters and payload specifications.

![API Browser Screen Capture]({{ site.baseurl }}/public/images/screenshots/screenshot1.png)

### Creating a MediaType

An API specification should define not only what the service accepts, but also
what it returns. One way to achieve this is to use application-specific
internet media types in responses. And for extra credit we can also define the
associated attribute structure of these media types.

In Praxis, media types:

- **define their representations** by declaring classes that extend ```Praxis::MediaType```
- **can be associated with resource definitions** as a default internet media type
- **document the their representations** and their use in resource definitions

So, how does that work for your Posts resource? Very easily.

Start by defining the representation of your ```Post``` media type by creating a
class derived from ```Praxis::MediaType```. In that class, specify your internet
mediatype name (i.e. 'application/vnd.acme.post') using the ```identifier``` DSL
method and proceed to define the media type's attributes.

The ```create``` action already describes two attributes for a ```Post```
resource, but you can add more. In this example, you'll add an ```id``` and an
```href```.

Once you have all the possible attributes listed, you can define one or more
named views using a ```view``` DSL block. Each view may include a different
subset of attributes to display. Views are very useful when we wish to render
different attributes for different purposes. In this case, create a
```default``` view that contains all the attributes and a ```link``` view
containing only the href of the post:

{% highlight ruby %}
# design/v1/media_types/post.rb
module V1
  module MediaTypes
    class Post < Praxis::MediaType
      identifier 'application/vnd.acme.post'

      attributes do
        attribute :id, Integer, description: "Post identifier"
        attribute :href, String, description: "Unique Href for this Post"
        attribute :title, String, description: "Title for the Post"
        attribute :content, String,  description: "Post body contents"
      end

      view :default do
        attribute :id
        attribute :title
        attribute :content
      end

      view :link do
        attribute :href
      end
    end
  end
end
{% endhighlight %}

Save this as design/v1/media_types/post.rb and there you have it! A full Post
media type. So now, how do you associate this Post media type with your Posts
resource?

To use this newly defined media type, change the ``media_type``` declaration
in our Posts resource definition from th 'application/json' string to the full
class. By doing this, Praxis will know that, by default, actions belonging to the
```Posts``` resource definition are likely to generate responses of this
MediaType.

{% highlight ruby %}
# design/v1/resources/post.rb
module V1
  module Resources
    class Posts
      include Praxis::ResourceDefinition
      version '1.0'
      media_type MediaTypes::Post
    end
  end
end
{% endhighlight %}

Resource's default media types are used when response declarations
that can take a ```media_type``` parameters are left unspecified. For example,
our `response :ok` in the show action is equivalent to `response :ok, media_type: MediaTypes::Post`.

Associating a default MediaType to a resource definition has another convenient
effect when defining payload attributes. It can help simplify syntax. Here's
how:

It is good practice in RESTful APIs to be able to accept incoming resource
payloads that closely match resource responses receive from the same API. If
you get a result from a ```show``` action, you should be able to easily modify
parts of it, and re-POST it to the API to save some changes. Because of this,
Praxis will assume that any payload definition of any action is closely related
to the default MediaType of the Resource. By doing that, the designer can
define attributes by name, without being required to specify the type and/or
options that might exist in the associated MediaType.

In other words: payloads you define can inherit any attribute definition of the
same name that exists in the MediaType associated with the resource definition.

So, by adding the default mediatype in the Posts resource, your ```create```
action payload can be simplified from:

{% highlight ruby %}
# design/v1/resources/post.rb
action :create do
  routing do
    post ''
  end

  payload do
    attribute :title, String,
      required: true,
      description: "Title for the Post"
    attribute :content, String,
      description: "Post body contents"
  end
end
{% endhighlight %}

to:

{% highlight ruby %}
action :create do
  routing do
    post ''
  end

  payload do
    attribute :title, required: true
    attribute :content
  end
end
{% endhighlight %}

Now you have integrated a fully defined MediaType with your resource
definition. If you regenerate the documentation and take a peek, you'll now see
its full definition in all its glory.

Please see [media types](../reference/media-types/), for more information.

At this point you have designed a ```Posts``` resource with actions. You have
defined their routes, their parameters and an associated MediaType structure
with some renderable views, all without writing a single line of controller or
business logic code. Pretty groovy, huh?

Discussing the API interface at this stage, using the API browser, might save *a
lot* of time and effort before proceeding with the implementation of the actual
business logic. But now it's time for implementation.

## Implementation Phase

Praxis controllers are semantically very similar to any other "C" in most
existing MVC frameworks. They implement the business logic for the actions of a
resource and renderer a suitable response. Praxis controllers do differ from
those of other web frameworks in that Praxis controllers:

- are plain Ruby Objects (easy testing!)
- receive typed and named method parameters in their signature (with the types
  you have specified in your action definition of your resource)

### Creating a controller

To create your Posts controller, start with a Posts class which includes the
```Praxis::Controller``` module. Then use the ```implements``` method to tell
Praxis that this class implements the ```Posts``` resource definition.

Define a method for each your actions, show and create. The method signature
follows the named ```params``` attributes of your actions. The `show` action
has ```id``` and ```allow_deleted``` ```params``` and no ```payload```. The
```create``` action has a ```payload``` but no ```params```. The ```payload```
contents are not mapped to the method signature.

{% highlight ruby %}
# app/v1/controllers/posts.rb
module Controllers
  class Posts
    include Praxis::Controller
    implements V1::Resources::Posts

    def show(id:, allow_deleted:)
      response.headers['Content-Type'] = 'application/vnd.acme.post'
      # Do businessy logic here
      # look ma! id is an Integer!
      JSON.dump( V1::MediaTypes::Post.example.render(:default) )
    end

    def create
      # Do businessy logic here
      # I can do: payload.title   => and get the String type title from the incoming request body
      Responses::Created.new(created_post.href)
    end
  end
end
{% endhighlight %}

Please see [controllers](../reference/controllers/), for more information.

Your parameters are name-checked by Ruby at runtime, plus Praxis will make sure
their values conform to the type you've defined in your resource definition. If
there is any error loading or coercing values from the incoming request, Praxis
will return an appropriate validation error response telling you exactly what
happened. Score!

### Generating responses

Response generation is a broad topic, not covered in great detail here. In
general, a controller needs to return an instance of Praxis::Response-derived
class. There is one exception for strings. If you return a string from a
controller, Praxis will create an instance of the action's default response and
fill in the body with the string you returned.

There is much more related to responses that the framework provides, including
defining their expectations, specifying which actions can return which
resources, and runtime validation that returned responses match the specified
expectations.

Please see [responses](../reference/responses/), for more information.

### Generating examples

Example generation is another area that requires much more explanation.
However, for the sake of completeness, and because of the suspicious
```MediaTypes::Post.example.render(:default)``` call to generate a hash in the
`show` action), we should say a few words.

Praxis (in conjunction with its Praxis::Mapper and Attributor gem dependencies)
comes equipped with a very powerful way to:

- generate unique (or repeatable) examples of MediaType objects
- render them using any of their defined views

Rendering refers to generating a hash representation of a MediaType's
attributes. That hash can then easily be taken and output to the specific
desired format such as a JSON string.

In particular invoking a MediaType's ```.example``` class method will generate
an instance object with a fully-typed example structure as defined by its
attribute names and types. As a MediaType instance, you can then take that
object as ask it to be rendered according to one of the named views that you
have defined.

In this case, you have used the ```default``` view, which should produce a hash
with values for ```id```, ```title``` and ```content``` keys. Being able to
generate examples for all kinds of types makes for nice documentation, but it
also can create real-looking API responses for your tests.

## Conclusion

We now have a fully defined, and fully implemented Post API service. We can
review its docs, check the routes, start it up, and test that it responds
correctly in both success and error scenarios.

Start it up, and check it out!

{% highlight bash %}
$ rackup -p 8888

# Successful cURL call that shows post with ID 1
$ curl -i http://localhost:8888/my_posts/1 -H 'X-Api-Version: 1.0' -X GET

HTTP/1.1 200 OK
Transfer-Encoding: chunked
Server: WEBrick/1.3.1 (Ruby/2.1.2/2014-05-08)
Date: Tue, 19 Aug 2014 21:30:24 GMT
Content-Length: 65
Connection: Keep-Alive

{"id":108,"title":"indubitably","content":"advisedly"}

# Failed cURL call that tries to create a post with unknown attributes
$ curl -i http://localhost:8888/my_posts -H 'X-Api-Version: 1.0' -X POST -d 'My Post'

HTTP/1.1 400 Bad Request
Transfer-Encoding: chunked
Server: WEBrick/1.3.1 (Ruby/2.1.2/2014-05-08)
Date: Tue, 19 Aug 2014 21:42:54 GMT
Content-Length: 132
Connection: Keep-Alive

{
  "name": "ValidationError",
  "message": "Unknown attributes received: [:\"My Post\"] while loading $.payload"
}
{% endhighlight %}
