---
layout: page
title: FieldExpansion
---

* `FieldExpansion` provides a `Controller#expanded_fields` helper for
processing `:view` and/or `:fields` params to determine the final set fields
necessary to handle the request.
  * Note: This is primarily an internal extension used by the `MapperSelectors`
  and `Rendering` extensions, and is automatically included by them.
