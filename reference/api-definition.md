---
layout: page
title: API Definition
---
The ApiDefinition class is a singleton where you can define API-wide
constructs. Praxis allows you to define the following constructs in your
ApiDefinition:

Response Definitions
: Reusable response templates (see [Response Definitions](../response-definitions/))

API Information
: Global, or versioned, metadata about the api (see [API Information](../global-api-information/)).

Traits
: A convenient way to share common DSL elements across resource definitions and
actions (see [traits](../traits/)).


Below is a basic ApiDefinition that defines a response template, general info, and a trait:

{% highlight ruby %}
Praxis::ApiDefinition.define
  
  info do
    name 'Some App'
    title 'An example Praxis application'
    description 'A simple application meant for testing purposes'
    base_path '/'
  end

  info '1.0' do
    base_path '/v1'  
  end

  response_template :other_response do
    status 200
  end

  trait :authenticated do
    headers do
      key "Auth-Token", String, required: true
    end
  end
end
{% endhighlight %}

`Praxis::ApiDefinition` is a singleton that can be augmented at any point
during the bootstrapping process, but before any of your resource definitions
are loaded. This allows you to refer to the contents of your ApiDefinition from
your resource definitions. See [Bootstrapping](../bootstrapping/) for more
information on the various bootstrapping stages.
