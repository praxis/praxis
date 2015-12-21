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

  * If *neither* `:view` *or* `:fields` are defined in the action: the `:default` view will always be expanded.
  * If *only* `:view` is defined in the action: the system will expand the view name specified in the incoming request (or will use the `:default` view if one was not passed in the request).
  * If *only* `:fields` is defined in the action: the selected attributes from the `MediaType` are expanded. If no fields were selected in the request, the `:default` view is expanded .
  * If *both* `:view` *and* `:fields` are defined in the action: the system will expand view name passed in the request (or `:default` if none was passed), but restricted to the selectable fields that were passed in. In other words, will perform a intersection of the fields from the view and the fields passed in the request parameter.
