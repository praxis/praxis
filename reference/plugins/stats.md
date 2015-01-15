---
layout: page
title: Stats Plugin
---

The Stats plugin provides a statistics reporting interface that applications can use to send metrics to.

The plugin can be configured with two different collector types:

* `Harness::FakeCollector`: for using a collector that discards everything it receives (useful in some development modes). This is the default collector.
* `Harness::Statsd`: a collector that will send the metrics to a configurable statsd server.

Its configuration also allows to setup the method with which to send the metrics:

* either using an asynchronous queue (`Harness::AsyncQueue`): where all metrics are logged in a separate thread to never block the main thread
* or by using a synchronous queue (`Harness::SyncQueue`): where the reporting process will be responsible to send the stats on its own (useful for testing but not really used in practice)

The guts of this Plugin are backed by the [Harness](https://github.com/ahawkins/harness) gem.

## Using the plugin

The functionality of this plugin is available through its singleton methods. The method signature follows the well known statsd interface: count, increment, decrement, time ...

For example, the Praxis framework itself will increment the count of requests for a given status by invoking the following command for every request:

{% highlight ruby %}
Praxis::Stats.increment "rack.request.#{status}"
{% endhighlight %}

Similarly, it will record the overall duration of any received request under the 'rack.request.all' metric by:

{% highlight ruby %}
Praxis::Stats.timing('rack.request.all', duration)
{% endhighlight %}

The available singleton methods that the Plugin exposes are:

* count(*args)
* decrement(*args)
* gauge(*args)
* increment(*args)
* time(stat, sample_rate = 1, &block)
* timing(*args)

See the backing [Harness](https://github.com/ahawkins/harness) gem or the [Statsd](https://github.com/github/statsd-ruby) gem itself for more examples and inspiration.
