---
layout: page
title: FieldExpansion Extension
---

The `FieldExpansion` extension provides a `Controller#expanded_fields` helper for processing `:view` and/or `:fields` params to determine the final set of fields necessary to process the request.

Either, or both, of the `:view` and `:fields` params may be used, provided they are defined with the proper types:
 * `:view` must be of type `Symbol`, for example: `attribute :view, Symbol`.
 * `:fields` must be `Praxis::Types::FieldSelector` (or a scoped subclass), for example: `attribute :fields, Praxis::Types::FieldSelector.for(Person)`.

Regardless of what attributes are used, any attributes with types that are either a `MediaType` or a collection of a `MediaType` will be recursively expanded into a complete set of "leaf" attributes.


## Expansion logic

The exact expansion depends upon both the parameters defined on the action in question:
  * If *neither* `:view` *or* `:fields` are defined: the `:default` view is expanded.
  * If *only* `:view` is defined: the view specified in the request (or `:default` if one was not specified) is expanded.
  * If *only* `:fields` is defined: the selected attributes from the `MediaType` are expanded, or the `:default` view is expanded if no fields were selected.
  * If *both* `:view` *and* `:fields` are defined: the selected attributes from the specified view (or `:default` if one was not specified) are expanded.
