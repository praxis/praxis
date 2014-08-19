---
layout: page
title: Traits
---
Traits are a way to register common DSL functionality across your entire API,
and share them across different resource and action definitions.

## Declaring a Trait

Define traits through the ApiDefinition singleton. A trait definition requires
a name and a block of DSL elements. The block is not interpreted by the trait.
It will only be interpreted when resources or actions `use` it.

{% highlight ruby %}
Praxis::ApiDefinition.define do
  trait :data_range do
    params do
      attribute :start_at, DateTime
      attribute :end_at, DateTime
    end
  end

  trait :authenticated do
    headers do
      header :auth_token
    end
  end
end
{% endhighlight %}

The first example creates a trait named `data_range` which defines two incoming
parameters, `start_at` and `end_at`. If you write an action that uses this
trait, it would be as if you had added this params block directly to your
action.

The second example creates a trait named `authenticated`. All it does is define
a header named `auth_token` for you to use in your actions.

## Using a Trait

To use a trait, call the use method from within your action or resource
definition, and pass the name of the trait you want to use.

{% highlight ruby %}
class Blogs
  include Praxis::ResourceDefinition
  # the 'authenticated' trait will be inherited by all actions
  use :authenticated

  routing do
    prefix '/my_blogs'
  end

  action :index
    # the 'data_range' trait will only be used by the index action
    use :data_range
  end
end
{% endhighlight %}

In this case, all actions in `Blogs` resource definition will have the
`authenticated` header defined. The `index` action will have `start_at` and
`end_at` params defined. You can think of `use :trait_name` as a cut-and-paste
mechanism which allows you to reuse common snippets of design-time code.
