---
layout: page
title: FieldSelection
---

The `FieldSelection` extension adds an enhanced version of the  `Attributor::FieldSelector`
type, `Praxis::Extensions::FieldSelection::FieldSelector` (also aliased under `Praxis::Types::FieldSelector`).

Wraps `Attributor::FieldSelector` type and improves the definition
of parameters for a set of fields.

 * The parsed set of fields will be available as the `fields` accessor of
 the loaded value.
 * For example, to define a parameter that should take a set of fields
 for a `Person` media type, you would define a `:fields` attribute in the
 params like: `attribute :fields, FieldSelector.for(Person)`. The parsed
 fields in the request would then be available with
 `request.params.fields.fields`.


Usage:
Must be required explicitly with 'praxis/extensions/field_selection'.


## Field Selection Syntax

* a simple comma-separated list of attributes
  * sub-attributes may be selected by enclosing in parentheses, which may be nested as many times as desired.
* the parsed result is a hash with `true` indicating the field was selected, or another sub-hash with selected sub-attributes.

Examples:

* `a` - select the `a` attribute. yields: `{a: true}`
* `a(b)` - select the `b` sub-attribute of `a` (i.e. `a.b`). yields: `{a: {b:true}}`
* `a(b,c)` - select both `b` and `c` from `a`, yields: `{a: {b: true, c: true}}`
* `a(b(c))` - select `c` from `b` from `a` (i.e. `a.b.c`) yields: `{a: {b: {c: true}}}`
