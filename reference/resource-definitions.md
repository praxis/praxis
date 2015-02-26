---
layout: page
title: Designing API Resources And Their Actions
---
With Praxis, you can easily define the resources, routes and actions for your
application.

A resource definition is a class that contains configuration settings for a
resource. This may include routing information, definitions for actions you can
perform, its default media type, and more. To create a resource definition,
create a class which includes the `Praxis::ResourceDefinition` module. Below is
an example of a `Blogs` resource definition which includes a human-readable
description.

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition
  description <<-EOS
    Blogs is the Resource where you write your thoughts.

    And there's much more I could say about this resource...
  EOS
end
{% endhighlight %}


## Routing Prefix

Each resource definition has a routing prefix (partial path) which Praxis will
automatically prepend to all your resource's defined routes. By default, this
prefix is the class name of the resource definition converted to snake-case.
For our `Blogs` resource definition above, the default routing prefix is
`blogs`. To override the default routing prefix, simply include a routing block
in the resource definition and provide a value using the `prefix` method:

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition

  routing do
    prefix '/my_blogs'
  end
end
{% endhighlight %}

## Media Type

You can set the default media type of a resource definition using the
`media_type` method:

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition

  media_type BlogMediaType
end
{% endhighlight %}

A MediaType in Praxis is often more than just an Internet media-type string.
It commonly refers to the structure or schema with which a given resource type
will be displayed. This structure is also often associated with an Internet media-type string (i.e. 
the string is the `name` for the structure schema).

The value you pass to the media_type method must be a:

* Praxis::MediaType-derived class that defines the attributes and views
  available for representing an API resource.
* string representing an Internet media type identifier (i.e.
  'application/json').

For more information on Praxis media types, please see [Media
Types](../media-types/).

## Version

You can apply an API version to a resource definition by using the `version`
method:

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition

  version '1.0'
end
{% endhighlight %}

Setting the version of a resource definition allows you to have version control
over the resources available through the API.

You can use any string as a version. By using the version method, you're
telling Praxis to only dispatch actions for this resource when the incoming request
carries the correct version value.

An incoming request can specify a version in three different ways:

* By providing an `X-Api-Version` header containing the defined version string. Example: `X-Api-Version: 1.0`
* By providing an `:api_version` parameter in the query containing the defined version string. Example: `/blogs?api_version`
* By using an appropriate URL prefix. Example: `/v1.0/blogs`

The `version` method can take a `:using` option which allows you to restrict which of the three modes clients can use to specify versions.
The possible values corresponding to the three cases above are: `:header`,`:params` and `:path`. By default the allowed methods are `:headers` and `:params`. This means that the above definition of ```version 1.0``` is equivalent to ```version 1.0, using: [:header,:params]```.

Including the `:path` method has an effect to the routing prefixes, and will be reflected if you do `rake praxis:routes`.

By default the prefix matching for path versions is `"/v(version_string)/"`, but it can be easily changed by either:

* overriding `Praxis::Request.path_version_prefix` to return the appropriate string prefix ( by default this returns `"/v"` )
* or overriding `Praxis::Request.path_version_matcher` and providing the fully-custom matching regexp. This regexp must have a capture (named `version`) that would return matched version value. The system default is: `/^#{Request.path_version_prefix}(?<version>[^\/]+)\//`

Overriding these settings whould be rare but there are situations that might be required. For example, to conform to an already published version path, to add additional prefix segments or to allow case insensitive version strings.

## nodoc!

You can mark a resource for exclusion from generated documentation by using the `nodoc!` method:

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition

  nodoc!
end
{% endhighlight %}

Additionally, the resource's actions and media type (if specified) will not be used when determining which media types should be documented.


## Actions

To define which actions are available for a resource definition, use the
`action` method. At a minimum, an action definition must have a name and at
least one route. It's a good idea to add a description for each action so
Praxis can use it when generating documentation. In addition to a description
an action can also specify:

routing
: paths that should map to this action

params
: the structure of the incoming query string and the parameters you expect to
  find in it

payload
: the structure of the incoming request body

headers
: specific named headers that Praxis should parse and make available to this
  action

nodoc!
: this action should not be included in documentation. Also any types defined within
its payload or parameter blocks will not appear in the generated documentation.

Here is an example of a resource definition with a single `index` action, which
responds to a `GET /blogs` HTTP request:

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition

  action :index do
    routing { get '' }
    description 'Fetch all blog entries'
  end
end
{% endhighlight %}

### Routing

The routing block defines the way Praxis will map requests to your actions.
This DSL accepts one or mode entries of the form: HTTP verb, path (with colon
encoded capture variables), and options. For example:

{% highlight ruby %}
action :index do
  routing do
    prefix '/'
    get 'blogs'
    get 'orgs/:org_id/blogs'
  end
end
{% endhighlight %}

Praxis has convenience methods for all the HTTP verbs defined in the [HTTP/1.1
Specification](http://tools.ietf.org/html/rfc7231#section-4.3) (OPTIONS, GET,
HEAD, POST, PUT, DELETE, TRACE and CONNECT) plus
[PATCH](http://tools.ietf.org/html/rfc5789).

Praxis also accepts the 'ANY' verb keyword to indicate that the given route should
match for any incoming verb string. Routes with concrete HTTP verbs will always
take precendence against 'ANY' verb routes. For instance, take a look at the following 
simplistic and contrived example:

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition

  action :index do
    routing { get '/' }
    description 'Fetch all blog entries'
  end
  action :other do
    routing { any '/' }
    description 'Do other stuff with non GET verbs'
  end
end
{% endhighlight %}

In this case an incoming `"GET /"` request will always invoke the `:index` action, 
while others like `"POST /"` or `"PATCH /"` will always map the the `:other` action. 
Using the 'ANY' verb is mostly a convenience to avoid repeating several routes with 
the same exact path for an action that needs to respond to all those verbs in the 
same manner. There is a subtle difference, however, and that is that using 'ANY'
will truly accept any incoming HTTP verb string, while listing them in several routes
will need to match the specific supported names. For example, an 'ANY' route like the
above will be able to match incoming requests like `"LINK /"` or `"UNLINK /"` (assuming the Web 
server supports it).

Remember that Praxis prefixes all your resource's routes with a string based
on the name of your enclosing resource definition class, in this case
'/blogs'. You can override the prefix for a single action if the
resource-wide prefix doesn't apply (like in the example above).

You can inspect the Praxis routing table using `rake praxis:routes`:

{% highlight bash %}
$ rake praxis:routes
+---------------------------------------------------------------------------+
| version |        path         | verb | resource | action | implementation |
+---------------------------------------------------------------------------+
| n/a     | /blogs              | GET  | Blogs    | index  | -n/a-          |
| n/a     | /orgs/:org_id/blogs | GET  | Blogs    | index  | -n/a-          |
+---------------------------------------------------------------------------+
{% endhighlight %}

### Query string params, embedded URL params, and payload

Praxis allows you to define the expected structure of incoming request
parameters in the query string, in the URL itself and in the request body
(payload). By doing so, you can let the framework perform basic request
validation and coercion of values into their expected types. This is also a key
component of the Praxis documentation generator.

#### Params

In Praxis actions, the `params` stanza is used to describe incoming parameters that can
be found in both the action path (route) or the query string. In case of name 
conflicts, parameters in the path always take precedence over parameters in 
the query string.

You can define the expected structure of URL and query string parameters by
using the `params` method with a block. Use the standard Attributor::Struct
interface to declare attributes.

For example, if you want to allow filtering your blog index by title, author id
and author name, you could define these params:

{% highlight ruby %}
action :index do
  routing { get '' }
  params do
    attribute :title, String
    attribute :author do
      attribute :id, Integer
      attribute :name, String
    end
  end
end
{% endhighlight %}

Query string parameters are parsed by Rack in a style that should be familiar
to Rack users. A query string that includes all the above parameters could look
like this:

{% highlight bash %}
title=Why%20I%20Ditched%20My%20Co-Working%20Space&author[id]=29&author[name]=Rebekah%20Campbell
{% endhighlight %}

#### Payload

Similar to params, you can define the expected structure of the request body
using the `payload` method. As in the case of `params`, Attributes are optional
by default, so mark them as required if they must be present so Praxis can
validate them for you.

{% highlight ruby %}
action :create do
  routing { post '' }
  payload do
    attribute :title, String, required: true
    attribute :text, String, required: true
    attribute :author do
      attribute :id, Integer, required: true
    end
    attribute :tags, Attributor::Collection.of(String)
  end
end
{% endhighlight %}

Praxis only accepts JSON encoded content types. For example, sending the
following request body with an 'application/json' content type will pass
validation:

{% highlight json %}
{
  "title": "Why I Ditched My Co-Working Space",
  "text": "Last summer I tried the start-up dream. I moved into...",
  "author": {
    "id": 29
  }
}
{% endhighlight %}

Note that unlike other frameworks like Rails and Sinatra, Praxis explicitly
distinguishes payload parameters from URL parameters (path and query string
parameters). Be sure not to expect any parameters coming from the request body
in the `params` accessor. Request body parameters will only appear in
`payload`.

#### Request headers

Action definitions can call out special request headers that Praxis validates
and makes available to your actions, just like `params` and `payload`.  Use the
`headers` method with the attributor interface for hashes to define request header
expectations:

{% highlight ruby %}
action :create do
  routing { post '' }
  headers do
    key "Authorization", String, required: true
  end
end
{% endhighlight %}

In addition to define a header `key` in the standard `Attributor::Hash` manner, Praxis
also enhances the DSL with a `header` method that can shortcut the syntax for 
certain common cases. The `header` DSL takes a String name and an optional expected value: 

* if no value is passed, the only expectation is that a header with that name is received.
* if a Regexp value is passed, the expectation is that the header value (if exists) matches it
* if a String value is passed, the expectation is that the incoming header value (if exists) fully matches it.

Any hash-like options provided as the last argument are going to be blindly passed along to the
underlying `Attributor` types. Here are some examples of how to define header expectations:

{% highlight ruby %}
headers do	
  # Defining a required header
  header "Authorization"
  # Which is equivalent to
  key "Authorization", String, required: true
  
  # Defining a non-required header that must match a given regexp
  header "Authorization", /Secret/
  # Which is equivalent to
  key "Authorization", String, regexp: /Secret/
  
  # Defining a required header that must be equal to "hello"
  header "Authorization", "hello", required: true
  # Which is equivalent to
  key "Authorization", String, values: ["hello"], required: true
end
{% endhighlight %}

Using the simplified `headers` syntax can cover most of your typical definitions, while the native 
Hash syntax allows you to mix and match many more options. Which one to use is up to you. They
both can perfectly coexist at the same time.


#### Responses

All actions must specify the list of responses that they can return. Do this by
using the `responses` method, and passing the list of response names.

{% highlight ruby %}
action :create do
  routing { post '' }
  response :on_a_break
end
{% endhighlight %}

Praxis already provides a set of common responses to work with, but an
application can register its own custom responses too. Each registered response
has a unique name which is the name to use in this `responses` stanza.

If the controller for this action can explicitly return any of the common HTTP errors, its resource definition for the action must also explicitly list those responses. For example, if the controller for the "show" action uses a 404 (`:not found`) to indicate that a given resource id is not present in the DB, the response `:not_found` must be defined in its list of responses. Another way to see this requirement is that any response class that any controller action can return, must have its name listed in the allowed responses of its resource definition.


For more information, please see [Responses](../responses/).

#### Action Defaults

There are often situations where many actions within a resource definition will
require a common subset of definitions. For example, a common set of URL parameters,
a common set of headers, traits or even a common set of allowed responses. 

Praxis allows you to easily define and share common pieces of code across all actions 
by placing their definitions inside an `action_defaults` block at the resource definition level. 
Here is an example:

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition

  action_defaults do
    params do
      attribute :dry_tun, Attributor::Boolean, default: false
    end
    response :bad_request
    use :authenticated
  end

  action :index do
    routing { get '' }
  end
  action :show do
    routing { get '/:id' }
    params do
      attribute :id, String
    end
  end

end
{% endhighlight %}

The example above will cause the the `:dry_run` parameter to be propagated and
defined in all available actions of the `Blogs` resource definition (i.e., both 
`:index` and `:show` actions will have such a parameter). The same exact
propagation will happen for the `:bad_request` response and the use of the 
`:authenticated` trait.

With `action_defaults` you can use `params`, `payload`, `headers`, 
`response` and `use` stanzas to propagate definitions to all existing actions.
If any of those stanzas are defined within an action itself Praxis will
appropriately merge them. Therefore, in this example, the `:show` action will 
end up with both the `:dry_run` and  the `:id` parameters.

In case of conflict while merging, Praxis will always give overriding preference 
to definitions found within the action block itself.

NOTE: Currently `action_defaults` does not support sharing `routing` blocks. It 
is probable, however, that this will be supported soon if the use case arises.

## Canonical Paths

You can specify which action should be used for the resource's canonical href with the `canonical_path` method:

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition

  canonical_path :show
end
{% endhighlight %}

If no `canonical_path` has been specified, Praxis will use the `:show` action by default.

You can then both generate and parse hrefs for resource by using:

  * `ResourceDefinition.to_href(<named arguments hash>)` to generate an href for the resource.
  * `ResourceDefinition.parse_href(<href String>)` to get a type-coerced hash of the parameters for the canonical action from the given string.

Given a controller (class or instance), you can use use those helpers by first calling its its `definition` method to retrieve the `ResourceDefinition` it implements, and then using either `to_href` or `parse_href` as described above.
