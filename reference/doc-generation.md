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
it's look and feel before shipping it to customers. The doc browser is built with
Angular.js, Sass and Bootstrap - each of these technologies allowing you to customise
the resulting app. Here are a few ways you can do it, we also have a collection
of [recipes on the project wiki](https://github.com/rightscale/praxis/wiki/Doc-Browser-Customisation-Recipees).

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

Any HTML templates that you put into ```docs/views``` will override templates that
the browser already uses.

### Customising via Hooks

Most of the actual documentation content is documentation of various types - the request params type, the request body type, the response headers type, etc.

Each type goes through a template resolver function that decides which view will end up rendering the type. You can add your own resolver function that can return an appropriate template for your type.

For this example, assume that we have defined a custom Set type. In `docs/app.js` we do:

{% highlight js %}
angular.module('DocBrowser', ['PraxisDocBrowser'])
.config(function($templateForProvider) {
  // this is a dependency injected function
  $templateForProvider.register(function($type, $requestedTemplate) {
    if ($type === 'Set') {
      if ($requestedTemplate === 'standalone') {
        return 'views/types/standalone/set.html';
      }
  });
});
{% endhighlight %}

Here we register a new resolver function that is dependency injected. There are several special variables you can inject: `$type` is the name of the type, `$family` is the name of type family this type belongs to (type families provide a generic way to render similar types), `$typeDefinition` is an object containing everything we know about the type and finally `$requestedTemplate` is one of `standalone`, `embedded`, `label` or `main`.

![template illustration](/public/images/template-illustration.png)

Standalone templates exist at a standalone context and take the full width of the page. Embedded templates are for types that exist as a value of a key in a parent type and are rendered in a three column table - they should be one or more `<tr>`s. Label templates display the name of a type - which can be a link or conceivably you may add a popover explaining something about your type. Main templates are used for overriding the whole page dedicated to that type.

The resolver function must return one of these possible values:

- a string or a promise of a string: this will be considered a url of a template which will be either requested over http or loaded from the local template cache.
- a link function or a promise of a link function: this will be linked at the appropriate place. Use this if you have a very small template or you want to make some dynamic adjustments to the template. You can get a link function like this:

     {% highlight js %}
     $templateForProvider.register(function($compile) {
       return $compile('<div>My template</div>');
     });
     {% endhighlight %}
- undefined: means that this resolver doesn't know how to handle the type/template combination. This will then invoke the next resolver in the queue. The built-in resolvers are equipped to handle any type (albeit not so well), so they will eventually pick this up.


## Shipping the Docs

Run ```rake praxis:docs:build```. This will create a directory called output,
which has the compressed, offline ready documentation in it. You can then put it into
S3 or GitHub pages or serve them in any other way.
