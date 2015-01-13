---
layout: page
title: Plugins
---

## Overview

Plugins provide a means to cleanly add new functionality to Praxis, either by extending the core classes with additional features, or by registering callbacks to run during request handling.

For example, extensions to the core classes might include:

 * Adding a `requires_authentication` directive to `ActionDefinition` to specify specify that the action requires an authenticated user. 
 * Encapsulate access to the information about the currently logged-in user with a `Request#current_user` method that might return a `User` object.
 * Inject a `before :action` filter into every `Controller` to perform authentication.


### Anatomy of a Plugin

What follows is an example plugin for user authentication, `SimpleAuthenticationPlugin`, broken into sections for explanation. 

*Note: each class is inside the `SimpleAuthenticationPlugin` module, it's merely omitted here for conciseness.*

Define the plugin's module, and include the `Praxis::PluginConcern` module:
{% highlight ruby %}
module SimpleAuthenticationPlugin
  include Praxis::PluginConcern
end
{% endhighlight %}


The inner `Plugin` class for `SimpleAuthenticationPlugin` is responsible for setting up the plugin's configuration details. We've also thrown in an `authenticate` instance method, because it seemed as good of a place as any.

{% highlight ruby %}
class Plugin < Praxis::Plugin
  # It doesn't make sense to use this plugin more than once, so 
  # let's include Singleton.
  include Singleton

  # Set default options, in this case the assumed path to the 
  # configuration file (relative to the application's root)
  def initialize
    @options = {config_file: 'config/authentication.yml'}
  end

  # Hardcode (because it's a singleton) where Praxis should
  # add the plugin's configuration definition to the application's.
  def config_key
    :authentication
  end

  # Define the plugin's configuration attribute(s), which in this case
  # is just a simple boolean for whether to require authentication for actions
  # by default, or only only specific actions.
  def prepare_config!(node)
    node.attributes do
      attribute :authentication_default, Attributor::Boolean, default: false,
        description: 'Require authentication for all actions?'
    end
  end

  # Implement a simple authenticate method that does nothing useful
  # other than illustrate doing something.
  def authenticate(request)
    request.current_user == 'guest'
  end

end
{% endhighlight %}

The plugin's `Request` module will be included in to `Praxis::Request`. So we add a simple `current_user` method.
{% highlight ruby %}
module Request
  def current_user
    'guest'
  end
end
{% endhighlight %}

Extensions to `Praxis::Controller` will typically want to register `before`, `after`, or `around` callbacks. Ours is no different:
{% highlight ruby %}
module Controller
  # extend AS::Concern so that we can use its included callback to easily register our callback in concrete controllers. Note that Praxis::Controller
  # also extends AS::Concern.
  extend ActiveSupport::Concern

  # and register our before :action in the included callbak
  # from AS::Concern
  included do
    before :action do |controller|
      action = controller.request.action
      if action.authentication_required
        unless Plugin.authenticate(controller.request)
          return Praxis::Responses::Unauthorized.new(body: 'unauthorized')
        end
      end
    end
  end

end
{% endhighlight %}

We add a handy `requires_authentication` method to action definitions in the `ActionDefinition` module.
{% highlight ruby %}
module ActionDefinition
  # and again, extend AS::Concern. This time so we can use
  # decorate_docs in the proper context.
  extend ActiveSupport::Concern


  included do
    # add an :authentication_required key to the generated documentation.
    # note: this is only for the generated JSON output, handling the display
    # in the doc browser is separate.
    decorate_docs do |action, docs|
      docs[:authentication_required] = action.authentication_required
    end
  end

  # simple requires_authentication dsl helper.
  def requires_authentication(value)
    @authentication_required = value
  end

  # and a quick authentication_required getter, defaulting to false.
  def authentication_required
    @authentication_required ||= false
  end

end
{% endhighlight %}



## Using a Plugin

In order to use a plugin named `MyPlugin`, you would typically have the following in your `config/environment.rb`:

{% highlight ruby %}
Praxis::Application.configure do |application|
  application.bootloader.use MyPlugin, **my_plugin_options
end
{% endhighlight %}



As outlined above, `MyPlugin` may be either a subclass of `Plugin` *or* a module that includes `PluginConcern`. In the latter case, Praxis will expect there to be a class named `Plugin`, e.g. `MyPlugin::Plugin`.


## Plugin Components

The two main components of a plugin in Praxis are:

* `Plugin`: The class that is instantiated for each use of the plugin (unless it includes `Singleton`, in which case its `instance` is used).
* `PluginConcern`: An `ActiveSupport::Concern` module that encloses extensions to core Praxis classes.

A plugin in Praxis *must* consist of a subclass of `Plugin`, and that subclass *may* be enclosed in a module that has included `PluginConcern`

## Plugin Bootstrapping and Configuration

Praxis processes your `Bootloader#use` invocations while loading environment.rb and performs a few actions to load your plugin:

1. The plugin module's `setup!` method is called. By default, that method will inject any relevant modules into the core Praxis classes, provided that is the first time the method has been called (in the event the plugin is used multiple times in one application).
2. An instance of that plugin's `Plugin` class is created and saved in the application's set of plugins. Or, if that subclass is a `Singleton`, then its `instance` is retrieved and used instead.

The configuration of the Plugin instance, however, is deferred until a separate `:plugin` stage during [bootstrapping](reference/bootstrapping). Praxis calls your plugin during the `:prepare`, `:load` and `:setup` sub-stages in that order using the following callback methods:

1. `prepare`: `Plugin#prepare_config(node)`, adds the plugin's configuration definition to the provided node from the application's own configuration.
2. `load`: `Plugin#load_config!`, loads relevant configuration data and returns it. Note that the callback is not responsible for setting anything on the application, that is taken care of by the stage.
3. `setup`: `Plugin#setup!`, any final initialization necessary before the application's code is loaded.
