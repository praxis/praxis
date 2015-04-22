---
layout: page
title: Bootstrapping
---
The process of bootstrapping a Praxis application consists of executing a well
known set of ordered stages described in the Bootloader. An application can
easily hook into the boot process by either executing Ruby code as the files
required by stages are loaded or by installing before and after hooks.  As part
of this bootstrapping process the application will typically install its
configuration into the Praxis application singleton, initialize or finalize its
objects, and load application-specific source code.

A Praxis application is represented by the ```Praxis::Application``` singleton
class. As a singleton, you can have only one application instance and it is
always referencable using ```Praxis::Application.instance```. This allows the
bootstrapping process to easily locate, configure and change any aspect of the
application code.

To kick-off the bootstrapping process, call the setup method of the
`Praxis::Application` singleton and run it through your favorite rack
server. Here's a simple example of a config.ru file to achieve that:

{% highlight ruby %}
# Example of a minimalistic config.ru
require 'bundler/setup'
require 'praxis'

application = Praxis::Application.instance
application.setup

run application
{% endhighlight %}

## Bootloader

The bootloader is the class that determines the sequence of stages that will be
executed as the application starts. This process is automatically triggered
when the ```setup``` method of the application is invoked.

The Bootloader works by setting up a set of 'stages', and executing them in
order. Each stage has a unique name. An application can dynamically register
before and after hooks for each existing stage in order to execute code at the
right moment of the bootstrapping process.  It is possible to register a
before/after callback for a stage that hasn't been registered yet (as late as
the before hooks for that stage are run).

Stages can have sub-stages, and sub-stages can have their own sub-stages and so
on. This allows you to create logical groups of stages. Before hooks of a
parent stage get executed before any of the before/after hooks of its
sub-stages. After hooks of a parent stage get executed after all the before and
after hooks of its sub-stages.

Note: Currently, stages can only be removed. In the future (if needed) we might
want to add support for adding stages within a given position relative to
others, so that they can be arranged and/or attached in correct order.

### Default boot stages

The Bootloader will automatically create the following stages by default:

environment
: ^
- Requires the config/environment.rb file
- Instantiates each plugin specified by the ```use``` directive and calls its
  `setup!` method
- Sets the default file layout if the app hasn't defined one yet. The layout
  facility lets applications define the structure and order of files to be
  loaded. See the [layout](#layout) section for details.

initializers
: Loads the files specified in the `initializers` key of the file layout which
  typically globs all files within the 'initializers' directory from the
  application root.

lib
: Loads the files specified in the `libs` key of the file layout which
  typically globs all files within the 'lib' directory from the application
  root.

design
: Loads application design
: ^
- loads each group of named files under the :design key of the layout
- the load order follows how the entries are defined in file_layout. This can
  be changed by overriding AppLoader#layout_order.

app
: Loads the application code (implementation):
: ^
- loads each group of named files under the :app key of the layout
- the load order follows how the entries are defined in file_layout. This can
  be changed by overriding AppLoader#layout_order.
- for each loaded "Controller" sets ts `app_config` and `root` accessors.

routing
: traverses all declared routes in of your resource definitions and creates
  appropriate entries in the main Praxis router. Requests matching the correct
  path, version, and conditions cause the router to invoke the matching method
  name (with the typed params as method arguments) in the controller that
  implements the action.

warn_unloaded_files
: determines if there are any files that exist within the application path, but
  haven't been loaded by any of the file_layout path patterns. If there are
  unloaded files in the paths, it will print a warning indicating which files
  were not loaded. Turn this off by deleting the stage `delete_stage
  :warn_unloaded_files` in the configure block.

## Layout

The layout is a way for you to tell Praxis where your source code lives. It is
essentially a nested set of name/pattern pairs. The layout tells Praxis which
files it should require at different stages of the bootloader. Praxis preserves
the load order of the stages as listed in the layout.  Naming each pattern
allows your application to install before and after hooks when the stage is
executed. See [Request Life Cycle
Callbacks](../controllers/#request-life-cycle-callbacks) for more information
on before and after hooks.

If you don't specify a custom layout, Praxis will install the following default
layout:

{% highlight ruby %}
Praxis::Application.instance.layout do
  layout do
    map :initializers, 'config/initializers/**/*'
    map :lib, 'lib/**/*'
    map :design, 'design/' do
      map :api, 'api.rb'
      map :media_types, '**/media_types/**/*'
      map :resources, '**/resources/**/*'
    end
    map :app, 'app/' do
      map :models, 'models/**/*'
      map :controllers, '**/controllers/**/*'
      map :responses, '**/responses/**/*'
    end
  end
end
{% endhighlight %}

## Configuration

Praxis' configuration facility allows you to define, set and use your
application's configuration. More specifically, Praxis lets you:

- Define the structure and types of the available configuration parameters
  which gives your application a clean, validated and coerced set of values
  that match your specifications. This allows the application to minimize
  boilerplate code and not worry about consistent error reporting during
  application startup.
- Set the actual values of the application configuration in a plugabble way so
  that the application deployer can decide how to best provide the correct
  parameters to each of your apps. While reading the values from one or
  multiple configuration files might be appropriate in some cases, reading
  values from environment variables or accessing a config service might be more
  appropriate in others.
- Access the values using a fully typed configuration object which allows the
  application code to be clean and readable, and ignorant of where the values
  came from.

Defining the configuration structure must be done at boot time, typically
within the environment stage. Setting the configuration values is also
typically done at boot time. While this might vary from app to app, it is
common to set all parameters early on in the boot process as well. Technically
speaking, it is possible to re-set the configuration at runtime, although this
should only be done if the application code is able to re-read those values
when they change. Accessing configuration can be done at any time.

### Define

Given an instance of your application, you can define the structure of its
configuration by passing a block to #config. Within the block, you can define
attributes in the same way you define attributes in a MediaType or
params/payload in an action. The DSL within such a #config block follow the
syntax of an ```Attributor::Struct```. You can call define with a block
multiple times if you need to define configuration in multiple places.

{% highlight ruby %}
Praxis::Application.instance.config do
  attribute :db do
    attribute :hostname, String, regexp: /^host-/
    attribute :port, Integer, default: 80, values: [80,8080,443]
    attribute :username, String
    attribute :password, String
  end

  attribute :log_level, String, required: true
end
{% endhighlight %}

### Set

After you've defined your application's configuration, you can set the actual
values to use when the application starts. You can call ```config=``` with any
object that satisfies your configuration definition. Since Praxis doesn't
mandate any particular configuration store it is up to us to go fetch the
values from the right place. In this example, we'll use a simple YAML file:

{% highlight ruby %}
values = YAML.load(File.read('./config/application.yml'))
# {
#   'db' => {
#     'hostname' => 'host-1234',
#     'username' => 'root',
#     'password' => 'mydbpass'
#   },
#   'log_level' => 'info'
# }
Praxis::Application.instance.config = YAML.load(values)
{% endhighlight %}

If there is any problem in loading the configuration, Praxis will halt and will
describe the exact problem it encountered. Typical loading errors include
invalid or uncoercible types received, values outside the specified range, or
missing attributes marked as required.

## Access

Accessing the configuration data is done through the ```config``` method in the
Application singleton. The object retrieved will have the characteristics and
types as you defined it. Structs like the one above will expose parameters as
method accessors. Other types as Hash or Attributor::Collection
will expose values as underlying hashes or arrays.

For example, retrieving the config data for the example above can be done by:

{% highlight ruby %}
app_config = Praxis::Application.instance.config
app_config.db.hostname
=> 'host-1234'
app_config.db.port
=> 80
{% endhighlight %}

Note: While we didn't explicitly set a db port, the system picked a suitable
default as specified in its attribute.

## Logging

Praxis provides a
[Logger](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/logger/rdoc/Logger.html)
for your application to use, accessible through the `logger` method in the
Application singleton:

{% highlight ruby %}
Praxis::Application.instance.logger.error "failed to catch tuna"
{% endhighlight %}

If you don't specifically set the logger, Praxis will create one for you and
connect it to STDOUT. If you want to set your own, just use the setter method
and pass an object that implements the logger interface:

{% highlight ruby %}
file = File.open('log.log', File::WRONLY | File::APPEND)
Praxis::Application.instance.logger = Logger.new(file)
{% endhighlight %}
