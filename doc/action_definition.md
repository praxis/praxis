# Resource Definitions and Actions

With Praxis, you can easily define the resources, routes, actions, and much
more, for your application.

## Resource Definitions

Let's start with a basic resource definition:
```ruby
class Blogs
  include Praxis::ResourceDefinition
end
```

The default routing prefix for a given resource, uses the resource name.

For the "Blogs" resource definition above, the routing configuration is
automatically set up such that the default routing prefix for all
actions is:
```ruby
  '/blogs'
```


### Customizing Your Routing Prefix

To override the default routing prefix, simply include a routing block
in your resource definition:
```ruby
class Blogs
  include Praxis::ResourceDefinition

  routing do
    prefix '/my_blogs'
  end
end
```

This will result in a custom routing prefix of:
```ruby
  '/my_blogs'
```

### Resource Definition Methods

For the examples in this section, it is assumed that the methods will
be called from within the body of the resource definition class.
```ruby
class Blogs
  include Praxis::ResourceDefinition

  # method calls go here
end
```


#### Media Type

To set the media type for your resource definition, use the ```media_type```
method, like this:
```ruby
media_type BookMediaType
```

For more information on media types, please see XXX.


#### Version

You can also set the version for your resource definition:
```ruby
version '1.0'
```

#### Action

Actions must be defined for your resource definition.
```ruby
action :my_custom_action do
end
```

Please see XXX for more information on actions.


#### Other Methods

Many methods available for a resource definition, are also available
at the action level, as well.

* `params`
* `payload`
* `headers`
* `responses`
* `response_groups`

If called at the resource definition level, the results are applied to
all actions for that resource definition.

If called at the action definition level, the results are merged with
those, if any, from the resource definition level.

Please see XXX for more information on their use.


## Actions
All actions must be defined before you can implement them. You can define
actions within your resource definitions by calling the ```action``` method.

Let's look at an example resource definition with one action definition:
```ruby
class Blogs
  include Praxis::ResourceDefinition

  action :index do
    routing { get '' }
    description 'Fetch all blog entries'
  end
end
```

### Routing
At a minimum, an action definition must have a name and at least one route.
It's a good idea to add a description so Praxis can use it when generating
documentation. By default, Praxis prefixes all your resource's routes with a
string based on the name of your resource definition class, in this case
'/blogs'. The routing block tells praxis how to map requests to actions. You
can inspect the Praxis routing table using ```rake praxis:routes```:
```sh
$ rake praxis:routes
+--------------------------------------------------------------+
| version |  path  | verb | resource | action | implementation |
+--------------------------------------------------------------+
| n/a     | /blogs | GET  | Blogs    | index  | -n/a-          |
+--------------------------------------------------------------+
```

You can add multiple routes to the same action by adding multiple method calls
in the routing block for your action. You may need to set the prefix if the
resource-wide prefix doesn't apply. Praxis has convenience methods for all the
HTTP verbs defined in the [HTTP/1.1
Specification](https://tools.ietf.org/html/rfc2616#section-9) (OPTIONS, GET,
HEAD, POST, PUT, DELETE, TRACE and CONNECT) plus
[PATCH](http://tools.ietf.org/html/rfc5789).
```
action :index do
  routing do
    prefix '/'
    get 'blogs'
    get 'orgs/:org_id/blogs'
  end
end
```

```sh
$ rake praxis:routes
+---------------------------------------------------------------------------+
| version |        path         | verb | resource | action | implementation |
+---------------------------------------------------------------------------+
| n/a     | /blogs              | GET  | Blogs    | index  | -n/a-          |
| n/a     | /orgs/:org_id/blogs | GET  | Blogs    | index  | -n/a-          |
+---------------------------------------------------------------------------+
```

### Query string params, embedded URL params, and payload
Praxis allows you to define the expected structure of incoming request
parameters in the query string, in the URL itself and in the request body
(payload). By doing so, you can let the framework perform basic request
validation and coercion of values into their expected types. This is also key
component of the Praxis documentation generator.

### Params
In Praxis actions, 'params' can come from both the action path (route) and
from the query string. Parameters in the path always take priority over
parameters in the query string.

You can define the expected structure of query string parameters by calling the
```params``` method with a block. Use the standard Attributor::Struct interface
to declare attributes. If you want to allow filtering your blog index by title,
author_id and author_name, you could define these params:
```ruby
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
```

Query string parameters are parsed by Rack in a style that should be familiar
to Rack users. A query string with all the above parameters could look like this:
```
title=Why%20I%20Ditched%20My%20Co-Working%20Space&author[id]=29&author[name]=Rebekah%20Campbell
```

In the same way, you can define the expected structure of the request body
using the ```payload``` method. Attributes are optional by default, so make them
required if they must be present so Praxis can do that validation for you.
```ruby
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
```

Praxis expects request bodies to be JSON-encoded. For example, this request
body would pass validation:
```json
{
  "title": "Why I Ditched My Co-Working Space",
  "text": "Last summer I tried the start-up dream. I moved into...",
  "author": {
    "id": 29
  }
}
```

### Request headers
Action definitions can call out special request headers that Praxis validates
and makes available to your actions in much the same way as request parameters
and payload data. Call the ```headers``` method and use the attributor interface to
define request headers:
```ruby
action :create do
  routing { post '' }
  headers do
    attribute :Authorization, String, required: true
  end
end
```
