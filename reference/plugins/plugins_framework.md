---
layout: page
title: Plugins Framework
---


To highlight the functionality and power available through the Plugins framework, it is best to start with a concrete example of a simple, yet complete one. What follows is an example plugin for user authentication, `SimpleAuthenticationPlugin`, broken into sections for explanation. 

 
## Anatomy of a Plugin

The first thing to do to create a Plugin is to define the plugin's module, and include `Praxis::PluginConcern`:

{% highlight ruby %}
module SimpleAuthenticationPlugin
  include Praxis::PluginConcern
end
{% endhighlight %}

*Note: each class in our examples below must live inside the `SimpleAuthenticationPlugin` module. We are merely omitting it here for conciseness.*

Then we'll need an inner `Plugin` class inside our defined `SimpleAuthenticationPlugin` module. This class is responsible for setting up the plugin's configuration details. We can also define any other utility methods that might seem appropriate for the Plugin. For example, we've thrown in an `authenticate` instance method, because it seemed as good of a place as any. 

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

  # Define the structure of the plugin's configuration attribute(s). In this
  # case it is just a simple boolean for whether to require authentication
  # for actions by default, or only only specific actions.
  # The `node` parameter is an empty Attributor::Struct to which we'll add
  # attributes.
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

If we define a `Request` module inside the plugin, it will automatically be included in `Praxis::Request`. So to add a simple `current_user` method to a Praxis `Request` it is enough to define it like this.

{% highlight ruby %}
module Request
  def current_user
    'guest' # hopefully a more sophisticated logic goes here
  end
end
{% endhighlight %}

Extensions to `Praxis::Controller` are done by defining a `Controller` module within the plugin. As in the case above, any code inside the module will be automatically included in `Praxis::Controller`. Controller extensions typically want to register `before`, `after`, or `around` callbacks. The code below shows an example of that, registering a `before :action` block for all controllers:

{% highlight ruby %}
module Controller
  # extend AS::Concern so that we can use its included callback to
  # easily register our callback in concrete controllers. Note that
  # Praxis::Controller also extends AS::Concern.
  extend ActiveSupport::Concern

  # and register our before :action in the included callback
  # from AS::Concern
  included do
    before :action do |controller|
      action = controller.request.action
      if action.authentication_required
        unless Plugin.instance.authenticate(controller.request)
          Praxis::Responses::Unauthorized.new(body: 'unauthorized')
        end
      end
    end
  end

end
{% endhighlight %}

Our example authentication Plugin needs to allow designers to tag certain actions as requiring an authenticated user. A clean way to achieve that is to provide a new DSL method available within an `ActionDefinition`. We can do that by adding a handy `requires_authentication` method within the `ActionDefinition` module of our plugin. Similarly, we can include a `decorate_docs` hook to the `ActionDefinition` module so that when documents are generated, this plugin has the chance to decorate the output for actions that `:authentication_required` is true.

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



## Enabling a Plugin

In order to use a plugin named `MyPlugin`, you need to invoke the `use` directive of the Praxis bootloader. To do so, you would typically have the following in your `config/environment.rb`:

{% highlight ruby %}
Praxis::Application.configure do |application|
  application.bootloader.use MyPlugin, **my_plugin_options
end
{% endhighlight %}


As outlined above, `MyPlugin` may be either a subclass of `Plugin` *or* a module that includes `PluginConcern`. In the latter case, Praxis will expect the module that contains a class named `Plugin`, e.g. `MyPlugin::Plugin`.


## Plugin Components

The two main components of a plugin in Praxis are:

* `Plugin`: The class that is instantiated for each use of the plugin (unless it includes `Singleton`, in which case its `instance` is used).
* `PluginConcern`: An `ActiveSupport::Concern` module that encloses extensions to core Praxis classes.

In addition, plugins that use the `PluginConcern` module may provide modules that should be included in the core Praxis classes. The modules must be named after the class they are to be included in to, at present the following classes are supported:

  * `Request`
  * `Controller`
  * `ResourceDefinition`
  * `ActionDefinition`
  * `Response`

A plugin in Praxis *must* consist of a subclass of `Plugin`, and that subclass *may* be enclosed in a module that has included `PluginConcern`

## Plugin Bootstrapping and Configuration

Praxis processes your `Bootloader#use` invocations while loading environment.rb and performs a few actions to load your plugin:

1. The plugin module's `setup!` method is called. By default, that method will inject any relevant modules into the core Praxis classes, provided that is the first time the method has been called (in the event the plugin is used multiple times in one application).
2. An instance of that plugin's `Plugin` class is created and saved in the application's set of plugins. Or, if that subclass is a `Singleton`, then its `instance` is retrieved and used instead.

The configuration of the Plugin instance, however, is deferred until a separate `:plugin` stage during [bootstrapping](/reference/bootstrapping). The `:plugin` stage, contains three sub-stages: `:prepare`, `:load` and `:setup`. Praxis will call your Plugins in this particular order by using the following callback methods:

1. `prepare`: The prepare phase will invoke the `Plugin#prepare_config!(node)` method. This phase adds the plugin's configuration definition to the provided `node` from the application's own configuration. The `node` parameter is an `Attributor::Struct` which can be enhanced with whatever attribute structure the plugin requires. Typically the code in `prepare_config!` will pass a block to the `node.attributes` method containing a structure of typed attributes. (see authentication example above)
2. `load`: The load phase is in charge of loading and returning the relevant configuration data (based on the structure defined in the previous phase). This is implemented in the `Plugin#load_config!` method. This callback method is only responsible for returning the loaded configuration data. Praxis will internally take care of validating and saving such data onto the appropriate place in the application. There is a default implementation of this method in the base Plugin class. Such default method will automatically return the contents of the `:config_file` attribute of the plugin, assuming that is `YAML`-parseable. So, for plugins that simply get their configuration through a single `YAML` file, they can setup their `:config_file` variable appropriately and skip implementing the `load_config!` method in the Plugin class. 
3. `setup`: The last phase is `setup`, and it allows the Plugin to perform any final initialization before the application's code is loaded. This is implemented in the `Plugin#setup!` method. The default implementation of this method is empty.

Note that these phases are invoked for all registered Plugins as a block, one phase after the other. In other words, all registered Plugins will go through the `prepare` phase first, before they all move to the `load` phase, and finally move onto the `setup` phase.

## Doc Browser Customization

It is possible to modify and enhance the Doc browser from plugins. To begin, you must register your plugin as extending the doc browser by calling `Praxis::Plugin#register_doc_browser_plugin(path)`, where `path` will be the path to the directory where you store the assets for your plugin. The best place to call this is in the `Plugin#setup!` method mentioned above. Once this is done, Praxis will automatically pick up your plugin's components into its build system. This allows you to do the following:

#### Add Dependencies

If you place a `bower.json` into your `path`, the `dependencies` field will be merged into a master `bower.json` and then the dependencies will be automatically installed and linked into the doc browser.

#### Override or Add Templates

You may choose to override any of the Praxis builtin templates, simply place them at a matching path within a `views` subdirectory and they will be automatically picked up.

#### Add Scripts

Any code you provide will be loaded after the core Praxis doc browser, but before any of the user's code. This will allow you to override any components from core you need as well as take advantage of any APIs exposed. You can also expose APIs to the user from your plugin. See [the doc browser customization wiki](https://github.com/rightscale/praxis/wiki/Doc-Browser-Customisation-Recipes) for more details.

#### Provide SCSS Styles

`path` will be made available to the user's `docs/styles.scss` file, but will not be included automatically. Therefore it is up to you to instruct users to add any necessary imports to use styles you provide.

#### Add Other Assets

Any assets not mentioned above will be copied to the user's `docs/output` directory on build. This way you can provide images, fonts or other assets in a plugin.
