---
layout: page
title: Extensions
---

Extensions are helper modules or classes we ship with Praxis that extend the default functionality. They can be extremely useful to reuse pattern, reuse boilerplate or provide common functionality. However, they are completely optional and must be explicitly required when you choose to use them.

Praxis currently includes the following extensions, all under the `Praxis::Extensions`
namespace:

  * [`FieldSelection`](./field_selection): adds an enhanced version of [`Attributor::FieldSelector`](https://github.com/rightscale/attributor/wiki/FieldSelector) suitable for defining API parameters that describe which fields to return in responses. I.e. a compatible (yet simplified) GraphQL type syntax for field selection.
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
