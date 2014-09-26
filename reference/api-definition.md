---
layout: page
title: Designing Global Api Constructs
---
The ApiDefinition class is a singleton where you can define API-wide
constructs. Praxis allows you to define the following constructs in your
ApiDefinition:

Response Definitions
: Reusable response templates (see [Response Definitions](../response-definitions/))

Traits
: A convenient way to share common DSL elements across resource definitions and
actions (see [traits](../traits/)).

In the future, the ApiDefinition will allow you to define many more API-wide
constructs.

Below is a basic ApiDefinition that defines a response template and a trait:

{% highlight ruby %}
Praxis::ApiDefinition.define
  response_template :other_response do
    status 200
  end

  trait :authenticated do
    headers do
      header "Auth-Token"
    end
  end
end
{% endhighlight %}

`Praxis::ApiDefinition` is a singleton that can be augmented at any point
during the bootstrapping process, but before any of your resource definitions
are loaded. This allows you to refer to the contents of your ApiDefinition from
your resource definitions. See [Bootstrapping](../bootstrapping/) for more
information on the various bootstrapping stages.
