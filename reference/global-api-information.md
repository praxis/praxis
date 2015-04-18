---
layout: page
title: Global API Information
---

It is possible to provide some global API information in the `ApiDefinition.define` block with the `info` method. You may define this metadata for all versions of your API, or only for a specific version. All definitions at the global level (i.e. those that do not specify a version) will be inherited by all versions. Any directive defined within a version will overwrite anything inherited, with the exceptions of `base_path` and `base_params`, which are added to an inherited value.

The following directives are supported:

 * `name`
 * `title`
 * `description`
 * `base_path`
 * `base_params`

Below is a basic ApiDefinition that defines global info as well info for a specific version:

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
