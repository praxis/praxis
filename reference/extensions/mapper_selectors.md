---
layout: page
title: MapperSelectors Extension
---

The `MapperSelectors` extension adds `Controller#set_selectors`, which sets selectors in the controller's `identity_map` that ensure the fields returned from `Controller#expanded_fields` (from the [`FieldExpansion` extension](./field_expansion)) are loaded for a given model when `identity_map.load(model)` is called.

This will `select` any required database columns, and `track` any relevant associations.

To use this extension, include it in a controller with `include Praxis::Extensions::MapperSelectors`. and define `before` callbacks on relevant actions that call `set_selectors`. For example: `before actions: [:index, :show] { |controller| controller.set_selectors }`
