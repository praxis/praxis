---
layout: page
title: Rendering Extension
---

The `Rendering` extension adds `render` and `display` helper methods to controllers that reduce common boilerplate when producing rendered representations of media types and setting response "Content-Type" headers.

`Controller#render(object, include_nil: false)` loads `object` into the
  the current applicable `MediaType` (as from `Controller#media_type`) and
  renders it using the fields provided by `Controller#expanded_fields` (from the
    `FieldExpansion` extension).

`Controller#display(object, include_nil: false)` calls `render` (above) with
    `object`, assigns the result to the current `response.body`, sets the
    response's "Content-Type" header to the appropriate MediaType identifier,
    and returns the response.

To use this extension, include it in a controller with `include Praxis::Extensions::Rendering`.
