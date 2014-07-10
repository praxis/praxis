# Resource Definitions and Actions

With Praxis, you can easily define the resources, routes, actions, and much
more, for your application.

A resource definition is a class that contains configuration settings for
a resource, such as routing information, definitions for actions you can
perform on the given resource, its default media type, and more.


Let's start creating a basic Blogs resource definition by including 
the ```Praxis::ResourceDefinition``` module, and writing a human description 
about what it represents:

```ruby
class Blogs
  include Praxis::ResourceDefinition
  description <<-EOS
    Blogs is the Resource where you write your thoughts.
    
    And there's much more I could say about this resource...
  EOS 
end
```


## Routing Prefix

Each resource definition will have a routing prefix (i.e. a partial path) which will 
automatically be prepended to all of its defined action routes. By default, Praxis
sets the route prefix to be the class's name (converted to snake-case).

For the "Blogs" resource definition above, the default routing prefix will be set to:

```ruby
  '/blogs'
```

To override the default routing prefix, simply include a routing block in the
resource definition and provide a value using the ```prefix``` method:

```ruby
class Blogs
  include Praxis::ResourceDefinition

  routing do
    prefix '/my_blogs'
  end
end
```

## Media Type

A resource definition can be associated with a default media-type by using
the ```media_type``` method:

```ruby
class Blogs
  include Praxis::ResourceDefinition

  media_type BookMediaType
end
```

A media-type is a Praxis::MediaType-deriveda class that defines the attributes and views available
for representing an API resource. In addition to a full MediaType class, this method can also 
accept a simple string denoting an internet media type identifier (i.e. 'application/json')

For more information on media types, please see XXX.


## Version

You can make a given resource definition to only respond to a given
API version by using the ```version``` method: 
```ruby
class Blogs
  include Praxis::ResourceDefinition

  version '1.0'
end
```
Setting the version of a resource definition allows you to have version control over 
the resources available through the API.

The value for a version is any string. Issuing this version command will cause
Praxis to only dispatch actions for this resource when the value of an incoming 
`X-Api-Version header` matches the defined version string.

## Actions

To define which actions are available for a resource definition, use the ```action```
 method. At a minimum, an action definition must have a name and at least one route.
It's a good idea to add a description for each action so Praxis can use it when generating
documentation. In addition to a description and routing information, an action can also
specify: 

* the type an structure of the query string and URL parameters expected to receive (if there are any)
* definition of the expected structure of the incoming payload (for HTTP verbs that can transmit a body)

Here is a basic example for a resource definition with a single :index action, which will respond to
a `GET /blogs` HTTP request:

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

Defining how to map requests to your actions is done through the `routing` block.
The block DSL accepts one or mode entries of the form: HTTP verb, a path (with colon encoded 
capture variables) and possibly a set of options. For example:

```
action :index do
  routing do
    prefix '/'
    get 'blogs'
    get 'orgs/:org_id/blogs'
  end
end
```

Praxis has convenience methods for all the HTTP verbs defined in the 
[HTTP/1.1 Specification](https://tools.ietf.org/html/rfc2616#section-9) (OPTIONS, GET,
HEAD, POST, PUT, DELETE, TRACE and CONNECT) plus
[PATCH](http://tools.ietf.org/html/rfc5789).

 Remember that Praxis prefixes all your resource's routes with a
string based on the name of your enclosing resource definition class, in this case
'/blogs'. You can override the prefix for a single action if the
resource-wide prefix doesn't apply (like done in the example above)


 You can easily inspect the Praxis routing table using ```rake praxis:routes```:

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


#### Params

In Praxis actions, 'params' can come from both the action path (route) and
from the query string. In case of name conflicts, parameters in the path always take priority over
parameters in the query string.

You can define the expected structure of query string parameters by using the
```params``` method with a block. Use the standard Attributor::Struct interface
to declare attributes. 

For example, if you want to allow filtering your blog index by title,
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

There are situations in which many actions within a resource definition will require
a common subset of params. Because of that, Praxis allows params to be propagated to an 
action if they are defined within its enclosing resource definition.

```ruby
class Blogs
  include Praxis::ResourceDefinition

  params do
    attribute :title, String
    attribute :author do
      attribute :id, Integer
      attribute :name, String
    end
  end

  action :index do
    routing { get '' }
  end
end
```

In the example above, we have moved the parameters definition out of the index action
and into the resource definition. This will cause the params to be propagated to the 'index'
(and all other existin) actions of this resource definition. Defining
the params at the enclosing resource definition level is a simple way to
make all actions inherit them. The 'params' from both the action
and resource definition are merged, with the action's 'params' taking
precedence, if there are any name conflicts.


#### Payload

Similar to the params, you can also define the expected structure of the request body
using the ```payload``` method. Attributes are optional by default, so mark them
as required if they must be present so Praxis can do that validation for you.
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

Praxis only accepts JSON encoded content types. For example, sending the following
request body with an 'application/json' content type will happily pass validation:
```json
{
  "title": "Why I Ditched My Co-Working Space",
  "text": "Last summer I tried the start-up dream. I moved into...",
  "author": {
    "id": 29
  }
}
```

Similar to 'params' described in the previous section, if 'payload' has
been defined on the resource definition, it will get inherited and merged with the
'payload' defined on the action itself, if any, with the action's 'payload'
taking precedence for any conflicts.


### Request headers

Action definitions can call out special request headers that Praxis validates
and makes available to your actions in much the same way as request parameters
and payload data. Use the ```headers``` method with the attributor interface to
define request headers:

```ruby
action :create do
  routing { post '' }
  headers do
    attribute :Authorization, String, required: true
  end
end
```

Similar to the methods described in the previous sections, if 'headers' has
been defined on the resource definition, it will get merged with the
'headers' defined on the action itself, if any, with the action's
'headers' taking precedence for any conflicts.


### Responses


Any given action must specify the list of responses that it can return.
This is done using the ```responses``` method, and passing the list of response names.

```ruby
action :create do
  routing { post '' }
  responses :on_a_break
end
```

Praxis already provides a set of system responses to work with, but an application can
register many other custom responses as they see fit. Each registered response has a
unique name, and those are the names to use in this ```responses``` stanza.

Please see XXX for more information on creating custom responses.

Similar to the methods described in the previous sections, if 'responses' has
been defined on the resource definition, it will get inherited and merged with the
'responses' defined on the action itself, if any, with the action's
'responses' taking precedence for any conflicts.


### Response Groups

Responses can also be organized by groups, and as such, we can also use the 
```response_groups``` stanza to define a whole set of responses to be returned in one shot. 
Please see XXX for more information on defining response groups.

For a given action, you can specify response groups using the
```response_groups``` method.
```ruby
action :create do
  routing { post '' }
  response_groups :oauth
end
```

Similar to the methods described in the previous sections, if 'response_groups' has
been defined on the resource definition, it will get inherited and merged with the
'response_groups' defined on the action itself, if any, with the action's
'response_groups' taking precedence for any conflicts.
