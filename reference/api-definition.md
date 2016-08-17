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
: Global, or versioned, metadata about the api (see [API Information](#global-information)).

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

# Global Information

It is possible to provide global API information in the `ApiDefinition.define` block with the `info` method. You may define this metadata for all versions of your API, or only for a specific version. All definitions at the global level (i.e. those that do not specify a version) will be inherited by all versions. Any directive defined within a version will overwrite anything inherited (except `base_path` and `base_params` which a version cannot override if they have been set at the default level).

There are several attributes that are _only_ allowed at global level:

* `endpoint` can define your fully qualified API's endpoint. It's used purely for documentation purposes and will not be used in any routing or route-generation.
* `version_with` will define what versioning "scheme" your application will use. By default it's set to `[:header, :params]`, meaning Praxis will look for either an  `X-Api-Version` request header *or* an `api_version` query parameter to determine the version of your API to use for processing the request. It is also possible to use a path-based versioning scheme by using `version_with :path`. See section below for details.
* `documentation_url` is a hint to users where they can find the final version of the API's documentation.

The rest of the directives are supported in both the global or version level:

 * `name`: A short name for your API
 * `title`: A title or tagline.
 * `description`: A longer description about the API.
 * `base_path`: Root path prepended to *all* routes.
 * `base_params`: Default parameters applied to all actions. Used to define any params specified in `base_path`.
 * `consumes`: List of [handlers](../handlers) the API accepts from clients (defaults to `'json', 'x-www-form-urlencoded'`).
 * `produces`: List of [handlers](../handlers) the API may use to generate responses (defaults to `'json'`).


Below is a basic ApiDefinition that defines global info, as well info for a specific version:

{% highlight ruby %}
Praxis::ApiDefinition.define

  info do
    name 'Some App'
    title 'An example Praxis application'
    description 'This is an example application API.'
    endpoint 'api.example.com'
    documentation_url 'https://docs.example.com/some-app/'
    consumes 'json', ''x-www-form-urlencoded''
    produces 'json', 'xml'
    base_path '/:app_name'
    base_params do
      attribute :app_name, String, required: true
    end
  end

  info '1.0' do
    base_path '/v1'
    # override the global description.
    description 'The first stable version of of this example API.'
  end

end
{% endhighlight %}

In this example, the given info for version 1.0 would have a `description` of "The first stable version of of this example API.", while the `base_path` would be "/:app_name/v1".

You can use the `base_path` and `base_param` directives to define the base routes and their params for re-use across your whole API, or for a specific version. These are applied "before" any prefixes that you specify in your resources and actions, and will *always* apply, before, and independently, of any `prefix` that may be defined.


## Path-Based Versioning

If you want to version your API based on request paths, set the `version_using` directive to `:path`, and specify an appropriate `base_path` matcher. This `base_path` matcher must include an `:api_version` variable in it (like any other action route) which Praxis will use to extract the exact version string when routing to your resources.

Below is a basic ApiDefinition that uses path-based versioning, and specifies a `base_path` with the `:api_version` placeholder:

{% highlight ruby %}
Praxis::ApiDefinition.define

  info do
    description 'An example an API using path-based versioning'
    version_using :path
    base_path '/api/v:api_version'
  end

  info '1.0' do
    description 'The first stable version of of this example API.'
  end

end
{% endhighlight %}

In the above example, Praxis will resolve the `base_path` for any resources in version "1.0" to "/api/v1.0".
