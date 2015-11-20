---
layout: page
title: MapperSelectors
---

* `MapperSelectors` adds `Controller#set_selectors`, which sets selectors
  in the controller's `identity_map` to ensure any fields and associations
  necessary to render the `:view` and/or `:fields` params specified in the
  request are loaded for a given model when `identity_map.load(model)` is called.
  * To use this extension, include it in a controller with
    `include Praxis::Extensions::MapperSelectors`, and define `before`
    callbacks on relevant actions that call `set_selectors`. For example:
    `before actions: [:index, :show] { |controller| controller.set_selectors }`
