---
layout: page
title: Plugins
---

Plugins provide a means to cleanly add new functionality to Praxis. This extra functionality can be enhanced in different areas of the framework: by dynamically extending core classes, or registering runtime hooks to be executed during request handling.

Here are a few different examples of what plugins can do:

* Add DSL directives available when defining resources and actions. For example, an authentication plugin can add a `requires_authentication` directive available to all `ActionDefinitions` to specify that the action requires an authenticated user.
* Enhance the `Request` object to carry contextual information. For example, expose a similar authentication plugin could add information about the currently logged-in user through the `Request#current_user` method, which when invoked might even return a fully loaded `User` object.
* Enforce application-wide logic. For example, the same authentication plugin could inject a before :action filter into every existing `Controller` to enforce the authentication checks, or install global middleware or around filters for specific common Controllers.
* Decorate resulting Praxis docs with attributes defined by the plugin. For example, we might want to include which actions require authentication to the generated documentation.

Please see [Plugins Framework](./plugins_framework/), to learn more details about how to use and develop new Plugins.

## Existing Plugins

There are some plugins that will be always bundled with the Praxis framework. Primarily because they are used by the Praxis framework itself, therefore it is not necessary to enable them to use them. This is the list of bundled plugins:

* [Stats](./stats/): A metrics collector plugin that is Statsd-compatible
* [Notifications](./notifications/) A Praxis wrapper to ActiveSupport Notifications

You can find other plugins on [our wiki page](https://github.com/rightscale/praxis/wiki/Plugins-and-Tools).
