---
layout: page
title: Controllers
---
In Praxis, controllers behave much the same as they do in other MVC-based web
frameworks &mdash; they expose actions which receive requests from API
consumers, operate on resources to service those requests, and return the
appropriate responses. In short, controllers are the glue which connects
actions and their responses to application business logic.

Praxis controllers differ from some other frameworks in that they:

* are plain Ruby classes that happen to include the `Praxis::Controller`
  module.
* execute an action by calling a method. Action methods accept Ruby named
  parameters corresponding to the attribute names of the resource definition.

By using plain Ruby classes, Praxis allows you to use the full power of Ruby.
You are not limited in your inheritance options, and your controller code can
be well-isolated and easily tested.

## Implementing a Controller

To implement a controller in Praxis, include the `Praxis::Controller` module in
your controller class and indicate which of your Resource Definitions it
implements by using the `implements` stanza.

{% highlight ruby %}
class Posts
  include Praxis::Controller

  implements PostsDefinition

  # Controller code...
end
{% endhighlight %}

Including the `Praxis::Controller` module enhances the class with methods such
as `implements`, `before`, and `after`.

The `implements` method is used to connect a controller with its
ResourceDefinition. Technically speaking there is nothing that prevents the
same class from being both a Resource Definition and its Controller,
implementing itself. Despite that being feasible due to the modularity that
Praxis provides, we discourage it in order to keep "definitions" logically
separate from "runtime code".

Once set, you can retrieve the `ResourceDefinition` for a controller with the `definition` method, which is defined on both the class and instance.

## Implementing an Action

A controller action is an instance method defined on a controller class. The
method's name must match an action defined in the controller's resource
definition.

For example, this resource definition class for `Posts` defines two actions
&mdash; `:index` and `:show`:

{% highlight ruby %}
class PostsDefinition
  include Praxis::ResourceDefinition

  media_type Post
  version '1.0'

  action :index do
    routing { get '' }
    description 'Fetch all blog posts'
  end

  action :show do
    routing { get '/:id' }
    description 'Fetch an individual blog post'
    params do
      attribute :id, Integer, required: true
      attribute :token, String
      attribute :allow_deleted, Attributor::Boolean
      attribute :extended_info, Attributor::Boolean
    end
  end
end
{% endhighlight %}

The controller implementing this resource definition must have instance methods
named `index` and `show` which accept the argument names described by the
params block from the resource definition.

{% highlight ruby %}
class Posts
  include Praxis::Controller

  implements PostsDefinition

  def index
    # empty method signature: the index action defines no parameters
  end

  def show(id:, token:, **other_params)
    # four parameters defined matching the names of the arguments
    # Note that ruby allows is to unpack only the names we care about
    # and leave the rest tucked away in the other_params hash
  end
end
{% endhighlight %}

Note that the `index` action has no parameters defined in its resource
definition so the method accepts no arguments.

On the other hand, the `show` action has four parameters defined in its
resource definition, so it can explicitly declare them as named method
arguments. Ruby gives you great flexibility in declaring named parameters with
the splat operator. It is up to the developer to choose how many explicit
arguments to list, and how many to tuck away inside an `other_params` hash. In
this case, the developer decided that `id` and `token` are important enough to
use as direct variables in the controller, while pushing the `allowed_deleted`
and `extended_info` into the other_params hash. Having this flexibility is
great for dealing with large number of parameters while keeping your controller
code tidy.

In addition to using named arguments for incoming parameters, Praxis will also
ensure their values match the types that you've specified in the Resource
Definition. Accessing the `id` variable within the `show` method will always
get you an Integer.


## Retrieving Headers and Payload Data

The `Praxis::Controller` module provides a `request` accessor which can be used
to retrieve the incoming `headers` and the `payload` data. The information under
these methods is type-curated much like parameter definitions. They are
accessible through methods matching your attribute names, and they will always
return values matching the type of your attribute (possibly coercing them if
necessary). 

You can also test if a value exists (or has been assigned by a `default` option) for an attribute with the `key?` method. This is useful in those cases where there is an important distinction between a user-provided `nil` value and the user simply not providing a value, as there is in "PATCH" requests. 

For completeness, the request object also gives you access to your `params` in
the same way, even though you already get them passed in as named arguments.

Here's an example of how to access these methods from a controller action:

{% highlight ruby %}
def show(id:, token:, **other_params)
  accept = request.headers.accept # Retrieve 'Accept' header
  if request.payload.key?(:view)  # whether a value was specified for 'view'
    view = request.payload.view   # Retrieve a 'view' parameter from the payload
  end
  id == request.params.id         # id argument will be the same as request.params.id
end
{% endhighlight %}


## Returning a Response

Every controller action is responsible for returning a Response object (an
instance of a Praxis::Response-derived class) with the right headers, status
code and body.  Praxis handles the work of delivering your responses to
clients.

Instead of having to create a Response object every time, each controller
instance comes with a pre-set response accessor containing an instance of the
Default response which is 200 OK unless you modify it. Your controller may use
and modify the default response or substitute it with another. Or it could
ignore the default accessor and return its own Response objects. Here's an
example of one way to use the default accessor:

{% highlight ruby %}
def show(id:, token:, **other_params)
  response.headers['Content-Type'] = 'text/plain'
  response.body = "This is a simple body"
  response
end
{% endhighlight %}

There is another way to use the default response. If your action returns a
string, Praxis will call response.body for you and implicitly use that
response.

{% highlight ruby %}
def show(id:, token:, **other_params)
  response.headers['Content-Type'] = 'text/plain'
  "This is a simple body"
end
{% endhighlight %}

## Request Life Cycle Callbacks

Praxis provides a way to register one or more callbacks before or after named
stages in the request life cycle. This is done using the `before` and `after`
methods which take zero or more params and a block for Praxis to execute.

To execute a callback before the `show` action runs, you could add:

{% highlight ruby %}
before actions: [:show] do
  puts "before action"
end
{% endhighlight %}

To execute a callback before the `validate` stage of the request cycle, but
only when the action is `index`, you could add:

{% highlight ruby %}
before :validate, actions: [:index] do |controller|
  puts "About to validate params/headers/payload for action: #{controller.request.action.name}"
end
{% endhighlight %}

The block receives the instance of your controller, which you can use to access
all of the controller's properties, including the request, the response, any
actions, etc.

For a complete discussion of what stages are available for use in your
callbacks, as well as how to use them, please refer to the [Request Life
Cycle](../request-life-cycle/) documentation.

