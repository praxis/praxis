---
layout: page
title: Generating Documentation
---
Praxis makes it easy to generate documentation for your app. To generate
documentation:

1. create one or more [resource definitions](../resource-definitions/)
2. create one or more associated [media types](../media-types/)
3. invoke the `praxis:api_docs` rake task

```rake praxis:api_docs``` generates JSON documents describing your resource
definitions and media types and writes them to a folder named `api_docs` in
your project root.

For example, you may have the following resource definition (along with a
suitable Blog media type):

{% highlight ruby %}
# app/resource_definitions/blogs.rb
class Blogs
  include Praxis::ResourceDefinition

  media_type Blog
  version '1.0'

  action :index do
    routing { get '' }
    description 'Fetch all blog entries'
  end

  action :show do
    routing { get '/:id' }
    description 'Fetch an individual blog entry'
  end
end
{% endhighlight %}

When you run ```rake praxis:api_docs```, you will see the generated
documentation in your ```api_docs``` directory. And when you run ```rake
praxis:doc_browser```, Praxis will start a web server so you can browse the
documentation in a more human-readable format. Point your favorite web browser
to http://localhost:4567 to see it.

{% highlight bash %}
$ rake praxis:doc_browser
[2014-07-16 11:17:39] INFO  WEBrick 1.3.1
[2014-07-16 11:17:39] INFO  ruby 2.1.2 (2014-05-08) [x86_64-darwin13.0]
[2014-07-16 11:17:39] INFO  WEBrick::HTTPServer#start: pid=62332 port=4567
{% endhighlight %}
