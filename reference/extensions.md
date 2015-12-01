---
layout: page
title: Extensions
---

Extensions are similar to [Plugins](../plugins), except for the ways they are not:

  * extensions are typically just modules (really `ActiveSupport::Concern`s) that provide
  additional logic and behavior to the specific class they're included in.
    * or, they are simply additional classes wrapped up in a file you `require`.
  * extensions do not have any configuration data
  * extensions never instantiated during application loading, nor do they
  provide callback hooks (beyond that from `ActiveSupport::Concern.included` )

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
