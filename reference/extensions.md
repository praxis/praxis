---
layout: page
title: Extensions
---

Extensions are modules or classes we ship with Praxis, that must be explicitly required and that extend the default functionality.

Praxis currently includes the following extensions, all under the `Praxis::Extensions`
namespace:

  * [`FieldSelection`](./field_selection): adds an enhanced version of `Attributor::FieldSelector`
  * [`Rendering`](./rendering): adds `render` and `display` helper methods to controllers to
reduce common boilerplate in producing rendered representations of media types
and setting response "Content-Type" headers.
  * [`MapperSelectors`](./mapper_selectors) adds `Controller#set_selectors`, which sets selectors
  in the controller's `identity_map` to ensure any fields and associations
  necessary to render the `:view` and/or `:fields` params specified in the
  request are loaded for a given model when `identity_map.load(model)` is called.
  * [`FieldExpansion`](./field_expansion) provides a `Controller#expanded_fields` helper for
processing `:view` and/or `:fields` params to determine the final set fields
necessary to handle the request.
