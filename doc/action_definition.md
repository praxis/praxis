# Defining Actions
All actions must be defined before you can implement them. You can define
actions within your resource definitions by calling the ```action``` method.
Let's look at an example resource definition with one action definition:
```ruby
class Blogs
  include Praxis::ResourceDefinition

  action :show do
    routing { get '' }
    description 'Fetch an individual blog entry'
  end
end
```

## Routing
At a minimum, an action definition must have a name and at least one route.
It's a good idea to add a description so Praxis can use it when generating
documentation. By default, Praxis prefixes all your resource's routes with a
string based on the name of your resource definition class, in this case
'/blogs'. The routing block tells praxis how to map requests to actions. You
can inspect the Praxis routing table with:
```sh
$ rake praxis:routes
+--------------------------------------------------------------+
| version |  path  | verb | resource | action | implementation |
+--------------------------------------------------------------+
| n/a     | /blogs | GET  | Blogs    | show   | -n/a-          |
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
action :show do
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
| n/a     | /blogs              | GET  | Blogs    | show   | -n/a-          |
| n/a     | /orgs/:org_id/blogs | GET  | Blogs    | show   | -n/a-          |
+---------------------------------------------------------------------------+
```

## Query string params and payload
Praxis allow you to define the expected structure of incoming request
parameters both in the query string and in the request body (payload). By doing
so, you can let the framework perform basic request validation and coercion of
values into their expected types. This is also key component of Praxis'
documentation generator.

Define the expected structure of query string parameters by calling the
```params``` method with a block. Use the standard Attributor::Struct interface
to declare attributes. If you want to allow filtering the blog index by title,
author_id and author_name, you could define these query string parameters:
```ruby
action :index do
  routing { get '' }
  params do
    attribute :title, Attributor::String
    attribute :author, Attributor::Struct do
      attribute :id, Attributor::Integer
      attribute :name, Attributor::String
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
using the 'payload' method. Attributes are optional by default, so make them
required if they must be present so Praxis can do that validation for you.
```ruby
action :create do
  routing { post '' }
  payload do
    attribute :title, Attributor::String, required: true
    attribute :text, Attributor::String, required: true
    attribute :author, Attributor::Struct do
      attribute :id, Attributor::Integer, required: true
    end
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

## Request headers
Action definitions can call out special request headers that Praxis validates
and makes available to your actions in much the same way as request parameters
and payload data. Call the 'headers' method and use the attributor interface to
define request headers:
```ruby
action :create do
  routing { post '' }
  headers do
    attribute :Authorization, Attributor::String, required: true
  end
end
```
