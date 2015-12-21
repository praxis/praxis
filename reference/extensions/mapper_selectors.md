---
layout: page
title: MapperSelectors Extension
---

The `MapperSelectors` extension adds `Controller#set_selectors`, which sets selectors in the controller's `identity_map` that ensure the fields returned from `Controller#expanded_fields` (from the [`FieldExpansion` extension](./field_expansion)) are loaded for a given model when `identity_map.load(model)` is called.

This will allow the mapper to save DB work and bandwidth by `select`ing only the required database columns, and `track`ing only the relevant associations, necessary to satisfy the output fields of the request.

To use this extension, include it in a controller with `include Praxis::Extensions::MapperSelectors`. and define `before` callbacks on relevant actions that call `set_selectors`. For example:

{% highlight ruby %}
before actions: [:index, :show] do |controller|
  controller.set_selectors
end
{% endhighlight %}
