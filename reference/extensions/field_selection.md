---
layout: page
title: FieldSelection Extension
---

The `FieldSelection` extension adds an enhanced version of the  [`Attributor::FieldSelector`](https://github.com/rightscale/attributor/wiki/FieldSelector) type, `Praxis::Extensions::FieldSelection::FieldSelector` (also aliased under `Praxis::Types::FieldSelector`). This may be used both generically (i.e., directly as `FieldSelector`), or scoped to a specific `MediaType` with `FieldSelector.for` so that it can perform validation.

After parsing, the selected set of fields is available as the `fields` accessor on the parameter.

For example, to define a parameter to select a set of fields from a `Person` media type, you would define a `:fields` attribute in the params like: `attribute :fields, Praxis::Types::FieldSelector.for(Person)`. The parsed fields in the request would then be available with `request.params.fields.fields`.

To use this extension, use  `require 'praxis/extensions/field_selection'`.


## Field Selection Syntax

The field selection syntax is a simple comma-separated list of attributes to select, with sub-attributes being selectable by enclosing them in curly-braces ("{}"). I.e., compatible with the basic selection hierarchy of GraphQL.

This is parsed by `FieldSelector` and translated to an equivalent nested hash, with field names as keys, and values of either `true` to indicate that field was selected or a sub-hash with additional sub-fields for selection.

Examples:

  * `a` - select the `a` attribute. Yields: `{a: true}`
  * `a{b}` - select the `b` sub-attribute of `a` (i.e. `a.b`). Yields: `{a: {b: true}}`
  * `a{b,c}` - select both `b` and `c` from `a`. Yields: `{a: {b: true, c: true}}`
  * `a{b{c}}` - select `c` from `b` from `a` (i.e. `a.b.c`). Yields: `{a: {b: {c: true}}}`
  * `a,b{c}` - select `a`, and the `c` sub-attribute of `b`. Yields: `{a: true, b: {c: true}}.`
