---
layout: page
title: Global API Information
---

It is possible to provide some global API information in the `ApiDefinition.define` block with the `info` method. You may define this metadata for all versions of your API, or only for a specific version. All definitions at the global level (i.e. those that do not specify a version) will be inherited by all versions. Any directive defined within a version will overwrite anything inherited. 

This is purely informational output in the JSON files, it is *not* used in the doc browser or anywhere else yet.

The following directives are supported:

 * `name`
 * `title`
 * `description`
 * `base_path`

Below is a basic ApiDefinition that defines global info as well info for a specific version:

{% highlight ruby %}
Praxis::ApiDefinition.define
  
  info do
    name 'Some App'
    title 'An example Praxis application'
    description 'This is an example application API.'
  end

  info '1.0' do
    base_path '/v1'  
    # override the global description.
    description 'The first stable version of of this example API.'
  end

end
{% endhighlight %}

