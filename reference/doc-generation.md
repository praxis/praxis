---
layout: page
title: Generating Documentation
---
Praxis makes it easy to generate documentation for your app. To generate
documentation:

1. create one or more [resource definitions](../resource-definitions/)
2. create one or more associated [media types](../media-types/)
3. invoke the `praxis:docs:generate` rake task

```rake praxis:docs:generate``` generates JSON documents describing your resource
definitions and media types and writes them to a folder named `docs/api` in
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

When you run ```rake praxis:docs:generate```, you will see the generated
documentation in your ```docs/api``` directory. And when you run ```rake
praxis:docs:preview```, Praxis will start a web server so you can browse the
documentation in a more human-readable format. Point your favorite web browser
to http://localhost:4567 to see it.

{% highlight bash %}
$ rake praxis:docs:preview
{% endhighlight %}

## Customising the Docs

The default generator will generate a ```docs``` folder for you. In this folder
you can customise the docs output. The docs app that ships with Praxis is a fully
featured documentation browser tool, but chances are that you will want to customise
it's look and feel before shipping it to customers. There are three principal ways how
to customise the application:

### Changing styles with style.scss

In your ```/docs``` directory you will find a file called ```styles.scss```, which
contains a single [SASS](http://sass-lang.com/) definition: ```@import 'praxis.scss'```.
Praxis curently runs on [Bootstrap](http://getbootstrap.com/). You can customise
all the [variables](http://getbootstrap.com/customize/#less-variables-section) before
this import, and override any styles after it. These will
be recompiled on save and served in the doc browser.

{% highlight scss %}
$link-color: red; // change all the links to red
@import 'praxis.scss';
{% endhighlight %}


<!-- TODO:
### Customising via Hooks

Some of our services provide hooks for customisation via their provider. TODO: add more details and API docs.

{% highlight js %}
angular.module('DocsApp', ['praxisDocBrowser']).config(function(TemplateProvider) {
  TemplateProvider.registerForType('image/png', '<img src="data:{{example}}" />');
});
{% endhighlight %} -->

### Overriding files through Dependency Injection

In your ```/docs``` directory you will find a file called ```app.js``` which contains
the following code:

{% highlight js %}
angular.module('DocsApp', ['PraxisDocBrowser']);
{% endhighlight %}

This code declares a new module that depends on the provided doc browser. That means that
if you provide a provider for any of the services that the doc browser is built on, this will
override the one provided by the doc browser itself.

Perhaps you want to add a greeting to the controller section of the app:

{% highlight js %}
angular.module('DocsApp', ['praxisDocBrowser']).controller("ControllerCtrl", function($scope, $stateParams, Documentation) {
  $scope.controllerName = $stateParams.controller;
  $scope.apiVersion = $stateParams.version;

  Documentation.getController($stateParams.version, $stateParams.controller).then(function(response) {
    $scope.$broadcast('Hello world!');
    $scope.controller = response.data;
  }, function() {
    $scope.error = true;
  })
});
{% endhighlight %}

<!-- TODO:
What is somewhat unusual is that we use DI for templates as well:

{% highlight js %}
angular.module('DocsApp', ['praxisDocBrowser'])
  .constant('AttributeDescriptionTemplate', '{{attribute.description}}<div>HEYA THERE!</dl>');
{% endhighlight %}

It should be noted that while this approach is extremely powerful, we don't provide the same
guarantees on API stability as we do with the other approaches.
-->

Any HTML templates that you put into ```docs/views``` will override templates that
the browser already uses.

## Shipping the Docs

Run ```rake praxis:docs:build```. This will create a directory called output,
which has the compressed, offline ready documentation in it. You can then put it into
S3 or GitHub pages or serve them in any other way.
