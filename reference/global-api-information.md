---
layout: page
title: Global API Information
---

It is possible to provide some global API information in the `ApiDefinition.define` block with the `info` method. You may define this metadata for all versions of your API, or only for a specific version. All definitions at the global level (i.e. those that do not specify a version) will be inherited by all versions. Any directive defined within a version will overwrite anything inherited, with the exceptions of `base_path` and `base_params`, which will always be enforced when defined globally.

The following directives are supported:

 * `name`
 * `title`
 * `description`
 * `base_path`
 * `base_params`

In addition to the above which may be specified globally or on a version, there is a `version_with` directive that is only applicable on the global version to define what versioning "scheme" your application will use. By default it's set to `[:header, :params]`, meaning Praxis will look for either an  `X-Api-Version` request header *or* an `api_version` query parameter to determine the version of your API to use for processing the request. To narrow it to one or the other scheme, you can set it to just that specific option (i.e. set it to `:header` to just use the `X-Api-Version` header and ignore any `api_version` param). There is an additional scheme, `:path`, described later.

Below is a basic ApiDefinition that defines global info, as well info for a specific version:

{% highlight ruby %}
Praxis::ApiDefinition.define
  
  info do
    name 'Some App'
    title 'An example Praxis application'
    description 'This is an example application API.'
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

You can use the `base_path` and `base_param` directives to define the base routes and their params for re-use across your whole API, or for a specific version. These are applied "before" any prefixes that you specify in your resources and actions, and will *always* apply, before and independently of any `prefix` that may be defined.


## Path-Based Versioning

If you want to version your API using request paths, you can set the `version_using` directive to `:path`, and specify a `base_path` that includes a special `:api_version` placeholder that Praxis will fill in as applicable when configuring the routing for your resources.

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
