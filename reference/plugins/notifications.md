---
layout: page
title: Notifications Plugin
---

The notifications plugin is a Praxis wrapper to ActiveSupport Notifications.

Using this plugin the application can do things like:

* subscribe (i.e. register a callback) to receive notifications whenever anybody published data to a given channel name
* publish data to a given channel (which will deliver the data to all subscribed parties by invoking the registered callbacks)

For example, there are two channels that the Praxis framework publishes data to, that any application can subscribe to:

* `rack.request.all`: for any receive request into the system
* `praxis.request.all`: for any request that is dispatched to a Praxis controller

The available singleton methods that the Plugin wraps over `ActiveSupport::Notifications` are:

* `publish(name, *args)`
* `instrument(name, payload = {}, &block)`
* `subscribe(*args, &block)`
* `subscribed(callback, *args, &block)`
* `unsubscribe(subscriber_or_name)`

See the extensive documentation of [ActiveSupport::Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) for more details
