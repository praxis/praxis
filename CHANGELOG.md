# Praxis Changelog

## next

## 2.0.pre.9

- Refined OpenAPI doc generation to output only non-null attributes in the InfoObject.
- Fixed filtering params validation to properly allow null values for the "!" and "!!" operators
- Simple, but pervasive breaking change: Rename `ResourceDefinition` to `EndpointDefinition` (but same functionality).
- Remove all deprecated features (and raise error describing it's not supported yet)
- Remove `Links` and `LinkBuilder`. Those seem unnecessary from a Framework point of view as they aren't clear most
applications would benefit from it. Applications can choose to add that functionality on their own if so desire.
- Rebuilt app generators: for new empty app, and example app.
- Updated default layout to match new naming structure and more concepts commonly necessary for normal applications.
- Completely removed the native Praxis API document browser in lieu of OpenAPI 3.x standards, and reDoc.

## 2.0.pre.6

- Removed the explicit `links` helpers from a `MediaType`. There was too much magic and assumptions built into it. Things can still be built in a custom basis (or through a plugin) if necessary.
- Removed documentation `linked_builder` annotations.
- Leave the `x-www-form-urlencoded` handler in place, but do not automatically register it for a Praxis app. To include the handler in your app register it by requiring the file `require 'praxis/handlers/www_form'` and then though `application.handler('x-www-form-urlencoded',Praxis::Handlers::WWWForm)`
- Remove the `primary_route` (and name) concept from routes.
- Added a pagination (and sotring) extension (and a Pagination Plugin for easier use)
  - New pagination and ordering query string type (with simple syntax, borrowing from JSON api pagination ). Page-based and cursor-based options:
    - examples for pagination: `page=5,items=50` or `by=email,from=joe@example.com,items=100`
    - examples for ordering: `name,last_name,-birth_date`
  - New DSL for defining the pagination and sorting parameters in Endpoint definitions
  - Support for pagination header (as per draft spec http://tools.ietf.org/id/draft-nottingham-http-link-header-06.txt)
  - Pagination/ordering implementation for controllers through an easy Plugin inclusion.
  - ActiveRecord and Sequel DBs supported
  - Reimplemented and enhanced Query Filtering Extensions
    - introduced support for 'is NULL' and 'is NOT NULL' for column values in filter syntax (`!` and `!!` operators without value). example: `name!` means (name IS NOT NULL) while `name!!` means (name IS NULL). Null (or not null) relationship conditions not supported.
    - support for nested join conditions (grouping where conditions in same join)
    - support for respecting association scopes when filtering in joins
    - ActiveRecord supported (Sequel support not done yet)

## 2.0.pre.5

- Added support for OpenAPI 3.x document generation. Consider this in Beta state, although it is fairly close to feature complete.

## 2.0.pre.4
- Reworked the field selection DB query generation to support full tree of eager loaded dependencies
  - Built support for both ActiveRecord and Sequel gems
  - Selected DB fields will include/map the defined resource properties and will always include any necessary fields on both sides of the joins for the given associations.
  - Added a configurable option to enable debugging of those generated queries (through `Praxis::Application.instance.config.mapper.debug_queries=true`)

## 2.0.pre.1

- Bring over partial functionality from praxis-mapper and remove dependency on same
  - Praxis::Mapper's ::Resource and ::SelectorGenerator are now included
- General cleanup and simplification

## 0.22.pre

- Builds an initial Rails embeddability/compatibility set of functions and helpers:
  - Refactored dispatcher methods so that instrumentation can be easily added on (but without building a flexible hook system that might decrease the performance)
  - Change `Praxis:Request` super classing to be definable by a module setter
    - Make `rails_compat/request_methods` to use it.
  - Built `rails_compat` extension. Which for now only:
    - changes `Praxis:Request` to derive from `ActionDispatch::Request`
    - Will load the RailsPlugin code
  - Built a `RailsPlugin` plugin which, for now, will:
    - emulate firing off the `action_controller` basic hooks (`start_processing` and `process_action`).
    - Add a few basic controller methods (which make some of the other mixing you might want to throw in your controllers happier). For example: the `head` method for controllers, as it is one of the most used for simple extensions. NOTE: The `render` method is not currently added.
    - NOTE: db and view runtime values on request processing not done (i.e., not integrated with Praxis’ DB or rendering frameworks)
- Include URI in the primitive types when generating docs and displaying them (as to not have a generic URI schema polluting the lists)
- Loosen up the version of Rack that Praxis requires. Adapted the old MultipartParser to be compabible with Rack 2x (but in reality we should see about reusing the brand new parser that 2x comes with in the future)
- Loosen up the version of Mustermann to allow for their latest 1.x series (which will be used by some of the latest gems with Rails 5 and friends)
- Fix and improve Doc Browser presentation
  - proper showing of substructures of payloads
  - mark required attrs with red star (and semi-required as orange)
  - display the existing special requirements as well
  - Added requirements for parameters as well (in addition to payload)
  - format member_options display better
- Make `MiddleWareApp` initialize lazily. This allows the main rack app (i.e., Rails) to be fully initialized by the time any code in the Praxis middleware gets touched (i.e., full ActiveRecord connection initialization...etc.)
- Removed 'Stats' plugin
- CGI.decode filter values in the `FilteringParams` extension

## 0.21

- Protect against `MediaType`s that do not have any links defined.
- More robust scanning of existing types when generating docs. Some types might have not been
  properly reported in the `schemas` section of the JSON docs if they were only used somewhere
  deep in some other type or action hierarchy
- Build doc browser support for defining top-level home pages for types.
  Apps can achieve the override by registering templates that respond to the ‘main’ type (instead of
  the other existing ‘label’,’embedded’ and ‘standalone’ modes).
- Enhance doc browser to show header and location expectations on action responses that have them
  defined
- Allow Plugin registration without requiring config_key
  - registration will select a default config_key based on the class name
- A new `documentation_url` global directive is exposed for authors to be able to
  indicate where documentation will be hosted.
  - If this is provided, the default _validation handler_ will add a `documentation`
    key to the response pointing at a url that should correspond to the documentation
    for the resource the user was requesting.
  - `Praxis::Docs::LinkBuilder` can be used to generate these documentation urls from
    the praxis application.
- You can now switch your doc browser to use HTML5 style urls (i.e.
  `/1.0/type/V1-MediaTypes-PriceFilter` instead of
  `/index.html#/1.0/type/V1-MediaTypes-PriceFilter`).
- Remove deprecated rake tasks.
- Remove some remaining inline styling in doc browser.
- Adds a `ExampleProvider.removeHandlersForKey` call. You can use `ExampleProvider.removeHandlersForKey('general')`
  to get rid of the default example if required.
- Make Traits accumulate block definitions for `params`,`headers` and `payload` rather than overriding them.
- Switch to lazy evaluation of `base_params` from `ApiDefinition` to properly inherit them into the resources
  and their corresponding actions even before the application's `MediaTtypes` have been finalized.
- Built the `MiddlewareApp` class to make it easy to run a Praxis app mounted as an intercepting
  middleware which will only forward requests down the stack if they didn't match any of its routes.
  - Note: it properly skips forwarding when 404s are purposedly returned by the application itself.
  - Note2: it also respects the `X-Cascade=pass` conventions.

## 0.20.1

- Doc generation: handle SimpleMediaTypes so that they don’t show up in the generated schemas.
- Ensure we require AS#Enumerable extension is loaded, which is required in the generator code.
- Add Date to the list of primitive types so that it does not show in the generated schemas.
- Enhance the `:created` response_template, so that it can take the associated media_type
- Doc Browser: fix route display to have the captures instead of the example

## 0.20.0

- You can now add a `bower.json` file to your `docs` folder. Any dependencies
  you list there will be included in the doc browser.
- The Plugin API now exposes `Praxis::Plugin#register_doc_browser_plugin(path)`,
  which allows plugins to register assets that will be included in the doc browser.
  This is a convenient way to share customizations and optional features amongst
  different API projects.
- Fixes an issue where an odd scrollbar would appear in some cases in the doc browser.
- Fixed a corner-case in doc generation which could omit certain existing MediaTypes
  (when these existed but there were never referenced in any other part of the app).
- Added `ApiGeneralInfo` to supported modules a `PluginConcern` can extend.
- Fixed `MediaType` support for attributor advanced requirements.
- Doc Browser now exposes an API to register functions that generate code examples.
  These can be registered with `ExamplesProvider.register` call.

## 0.19.0

- Handle loading empty `MediaTypeIdentifier` values (to return `nil`)
- Doc browser now displays examples for action responses.
- Added `Controller#media_type` helper that returns the `media_type` defined
  for the current response, or defaults to the one defined by the controller's
  resource definition.
- Added assorted extensions, all under the `Praxis::Extensions` module:
  - `FieldSelection` adds a new type, `Praxis::Extensions::FieldSelection::FieldSelector`
    that wraps the `Attributor::FieldSelector` type and improves the definition
    of parameters for a set of fields. Must be required explicitly from
    'praxis/extensions/field_selection'.
    - The parsed set of fields will be available as the `fields` accessor of
      the loaded value.
    - For example, to define a parameter that should take a set of fields
      for a `Person` media type, you would define a `:fields` attribute in the
      params like: `attribute :fields, FieldSelector.for(Person)`. The parsed
      fields in the request would then be available with
      `request.params.fields.fields`.
  - `Rendering` adds `render` and `display` helper methods to controllers to
    reduce common boilerplate in producing rendered representations of media types
    and setting response "Content-Type" headers.
    - `Controller#render(object, include_nil: false)` loads `object` into the
      the current applicable `MediaType` (as from `Controller#media_type`) and
      renders it using the fields provided by `Controller#expanded_fields` (from the
      `FieldExpansion` extension).
    - `Controller#display(object, include_nil: false)` calls `render` (above) with
      `object`, assigns the result to the current `response.body`, sets the
      response's "Content-Type" header to the appropriate MediaType identifier,
      and returns the response.
    - To use this extension, include it in a controller with
      `include Praxis::Extensions::Rendering`.
  - `MapperSelectors` adds `Controller#set_selectors`, which sets selectors
    in the controller's `identity_map` to ensure any fields and associations
    necessary to render the `:view` and/or `:fields` params specified in the
    request are loaded for a given model when `identity_map.load(model)` is called.
    - To use this extension, include it in a controller with
      `include Praxis::Extensions::MapperSelectors`, and define `before`
      callbacks on relevant actions that call `set_selectors`. For example:
      `before actions: [:index, :show] { |controller| controller.set_selectors }`
  - `FieldExpansion` provides a `Controller#expanded_fields` helper for
    processing `:view` and/or `:fields` params to determine the final set fields
    necessary to handle the request.
    - Note: This is primarily an internal extension used by the `MapperSelectors`
      and `Rendering` extensions, and is automatically included by them.
- A slew of Doc browser improvements:
  - Now uses the new JSON format for responses.
  - Traits now get exposed in the doc browser.
  - Now displays examples for requesting actions.
  - Now correctly displays top-level collections in action payloads.
  - Has improved scrolling for the sidebar.
  - Displays more detailed HTML titles.
  - Has been switched back to having a separate page per action, however actions are now shown in the sidebar.
  - Will now display multiply nested resources in a proper hierarchy.
- Fix doc generator to only output versions in index for which we have resources (i.e. some can be nodoc!)

## 0.18.1

- Fix Doc Browser regression, which would not show the schema in the Resource Definition home page.

## 0.18.0

- Added `display_name` DSL to `ResourceDefinition` and `MediaType`
  - It is a purely informational field, mostly to be used by consumers of the generated docs
  - It defaults to the class name (stripping any of the prefix modules)
- Revamped document generation to output a more compact format:
  - 1 file per api version: including info, resources, schemas and traits.
  - 1 single index file with global info plus just a list of version names
  - new task currently usable through `bundle exec rake praxis:docs:generate_beta`
    - NOTE: leaves the current doc generation tasks and code intact (until the doc browser is switched to use this)
- Specialized `Multipart`’s family in its description to be ‘multipart’ instead of ‘hash’.
- Added `Praxis::Handlers::FormData` for 'multipart/form-data'. Currently returns the input unchanged in `parse` and `generate`.
- Added `Praxis::Handlers::WWWForm` for form-encoded data.
- Added `Docs::Generator`, experimental new documentation generator. Use the `praxis:docs:experiments` rake task to generate. _Note_: not currently compatible with the documentation browser.
- Added 'praxis.request_stage.execute' `ActiveSupport::Notifications` instrumentation to contorller action method execution in `RequestStages::Action#execute`.
- Make action headers, params and payloads be required by default as it is probably what most people expect from it. To make any of those three definitions non-required, simply add the `:required` option as used in any other attribute definition. For example: `payload required: false do ...`

## 0.17.1

- Fixes an issue that would make exported documentation broken.
- Fixes an issue that would make the version selector broken.

## 0.17.0

- Merges action details pages into one long page in doc browser
- Refined path-based versioning:
  - Added `ApiGeneralInfo#version_with`, which defaults to `[:header, :params`] and may be set to `:path` to use path-based versioning.
  - Added support for specifying an `:api_version` placeholder to the global version's `ApiGeneralInfo#base_path`.
  - Deprecated `ResourceDefinition.version using: :path` option, use `ApiGeneralInfo#version_with` instead.
- Fix bug where before/after hooks set on sub-stages of `:app` would not be triggered
- Refactors the api browser to allow registering custom type templates.
  - This also removes an undocumented feature that did something similar.
  - Fixes an issue where Struct properties wouldn't be displayed.
- Added `endpoint` directive to global API info, only used for documentation purposes.
- Added `ResourceDefinition.parent` directive to define a parent resource.
  - The parent's `canonical_path` is used as the base of the child's routes.
  - Any parameters in the parent's route will also be applied as defaults in the child. The last route parameter is assumed to be an 'id'-type parameter, and is prefixed with the parent's snake-cased singular name. I.e., `id` from a `Volume` parent will be renamed to `volume_id`. Any other parameters are copied unchanged.
    - This behavior can be overridden by providing a mapping hash of the form `{parent_name => child_name}` to the `parent` directive. See [VolumeSnapshots](spec/spec_app/design/resources/volume_snapshots.rb) for an example.
- Backwards incompatible Change: Refactored `ValidationError` to be more consistent with the reported fields
  - Changed `message` for `summary`. Always present, and should provide a quick description of the type of error encountered. For example: "Error loading payload data"
  - Semantically changed `errors` to always have the details of one or many errors that have occurred. For example: "Unknown key received: :foobar while loading \$.payload.user"
  - Note: if you are an application that used and tested against the previous `message` field you will need to adjust your tests to check for the values in the `summary` field and or the `errors` contents. But it will now be a much more consistent experience that will allow API clients to notify of the exact errors and details to their clients.
- Added `Application.validation_handler` to customize response generation for validation errors. See [validation_handler.rb](lib/praxis/validation_handler.rb) for default version.
- Copied mustermann's routers to praxis repo in anticipation of their removal from mustermann itself.
- Added response body validation.
  - Validation is controlled by the `praxis.validate_response_bodies` boolean
    config option, and uses the `media_type` defined for the response definition.
- Added `location:` option to `Responses::Created.new`.
- `ResourceDefinition.parse_href` now accepts any instance of `URI::Generic` in addition to a string.
- Fixed path generation for nested ResourceDefinitions
- Substantial changes and improvements to multipart request and response handling:
  - Added `Praxis::Types::MultipartArray`, a type of `Attributor::Collection` with `Praxis::MultipartPart` members that allows the handling of duplicate named parts and unnamed ones. The new type supports defining many details about the expected structure of the parts, including headers, payloads, names and filename information. In addition, this type is able to load and validate full multipart bodies into the expected type structure, generate example objects as well as dump them into a full multipart body including boundaries and properly encoded parts following their content-types. See documentation for details and more features.
  - Made `Praxis::MultipartPart` a proper `Attributor::Type`.
  - Added `Praxis::Responses:MultipartOk` properly returning `MultipartArray` responses.
  - Deprecated `Praxis::Multipart`. A replacement for true hash-like behavior will be added before their removal in 1.0.
- `ActionDefinition#response` now accepts an optional second `type` parameter, and optional block to further define that type. The `type` provided will be used to specify the `media_type` option to pass to the corresponding `ResponseDefinition`.
- The `header` directive inside `ActionDefinition#headers` now accepts an optional second `type` parameter that may be used to override the default `String` type that would be used.
- Added `Praxis::Handlers::Plain` encoder for 'text/plain'.
- Fixed `Praxis::Handlers::XML` handler to transform dashes to underscores and treat empty hashes like ActiveSupport does.
- Adds hierarchival navigation to the doc browser.
- Adds a ConfigurationProvider allowing for easy doc customization.

## 0.16.1

- Fixed a bug where documentation generation would fail if an application had headers in a Trait using the simplified `header` DSL.

## 0.16.0

- Overhauled traits: they're now represented by a `Trait` class, which are created from `ApiDefinition#trait`.
  - `ApiDefinition#describe` will also include details of the defined traits.
  - `ResourceDefinition#describe` and `ActionDefinition#describe` will also include the names of the used traits.
  - _Note_: this may break some existing trait use cases, as they are now more-defined in their behavior, rather than simply stored blocks that are `instance_eval`-ed on the target.
- Deprecated `ResourceDefinition.routing`. Use `ResourceDefinition.prefix` to define resource-level route prefixes instead.
- Significantly refactored route generation.
  - The `base_path` property defined in `ApiDefinition#info` will now appear in the routing paths 'base' (instead of simply being used for documentation purposes).
    _Note_: unlike other info at that level, a global (unversioned) `base_path` is _not_ overriden by specific version, rather the specific version's path is appended to the global path.
  - Any prefixes set on a `ResourceDefinition` or inside a `routing` block of an ActionDefinition are now additive. For example:
    - Setting a "/myresource" prefix in a "MyResource" definition, and setting a "/myaction" prefix within an action of that resource definition will result in a route containing the following segments ".../myresource/myaction...".
    - Prefixes can be equally set by including `Traits`, which will follow exactly the same additive rules.
  - To break the additive nature of the prefixes one can use a couple of different options:
    - Define the action route path with "//" to make it absolute, i.e. a path like "//people" would not include any defined prefix.
    - Explicitly clear the prefix by setting the prefix to `''` or `'//'`.
- Added `base_params` to `ApiDefinition#info` as a way to share common action params
  - `base_params` may be defined for a specific Api version, which will make sharing params across all Resource definitions of that version)
  - or `base_params` may be defined in the Global Api section, which will make the parameters shared across all actions of all defined Api versions.
- Fixed `MediaType#describe` to include the correct string representation of its identifier.
- Allow route options to be passed to the underlying router (i.e. Mustermann at the moment)
  - routes defined in the `routing` blocks can now take any extra options which will be passed down to the Mustermann routing engine. Unknown options will be ignored!
  - Displaying routes (`praxis routes` or `rake praxis:routes`) will now include any options defined in a route.
  - Added an example on the instances resource of the embedded spec_app to show how to use the advanced `*` pattern and the `:except` Mustermann options (along with the required `:splat` attribute).
- Spruced up the example app (generator) to use the latest `prefix` and `trait` changes

## 0.15.0

- Fixed handling of no app or design file groups defined in application layout.
- Handled and added warning message for doc generation task when no routing block is defined for an action.
- Improved `link` method in `MediaType` attribute definition to support inheriting the type from the `:using` option if if that specifies an attribute. For example: `link :posts, using: :posts_summary` would use the type of the `:posts_summary` attribute.
- Fixed generated `Links` accessors to properly load the returned value.
- Added `MediaTypeIdentifier` class to parse and manipulate Content-Type headers and Praxis::MediaType identifiers.
- Created a registry for media type handlers that parse and generate document bodies with formats other than JSON.
  - Given a structured-data response, Praxis will convert it to JSON, XML or other formats based on the handler indicated by its Content-Type.
  - Given a request, Praxis will use the handler indicated by its Content-Type header to parse the body into structured data.
- Fixed bug allowing "praxis new" to work when Praxis is installed as a system (non-bundled) gem.
- Fixed doc generation code for custom types
- Hardened Multipart type loading

## 0.14.0

- Adds features for customizing and exporting the Doc browser, namely the following changes:
  1. All doc browser stuff is now centralised under the `praxis:docs` namespace.
  2. The doc browser requires node.js. (TODO: add this to the docs PR)
  3. `rake praxis:docs:generate` generates the JSON schema files. `rake praxis:api_docs` is now an alias of this with the idea that `rake praxis:api_docs` will be deprecated.
  4. `rake praxis:docs:preview` will open a browser window with the doc browser. It will refresh automatically when the design files change as well as when any customisations change.
  5. `rake praxis:docs:build` will generate a fully built static version of the app in `docs/output`. This can then be put on S3 or GH pages and should work.
  6. The default app generator will now generate a docs directory with some files to get you started.
  7. Any `.js` file in the `docs` directory will be included in the doc browser. Angular's dependency injection allows users to override any service or controller as needed.
  8. The default `docs/styles.scss` simply `@import 'praxis'`. However this means the user can override any of bootstraps variables allowing for easy theme customisation. Rules etc. can now also be overridden.
  9. Any templates defined in `docs/views` take precedence over those defined in the doc browser. This means the user can easily customise parts of the app, while leaving the rest up to us.
  10. Any changes to the above customisations will be automatically reloaded on save.
- First pass at describing (and doc-generating) API global information
  - Inside a `Praxis::ApiDefinition.define` block one can now specify a few things about the API by using:
    - info("1.0") `<block>` - Which will apply to a particular version only
    - info `<block>` - Which will be inherited by any existing API version
    - The current pieces of information that can be defined in the block are: `name`, `title`, `description` and `basepath`. See [this](https://github.com/rightscale/praxis/blob/master/spec/spec_app/design/api.rb) for details
  - NOTE: This information is output to the JSON files, BUT not used in the doc browser yet.
- Changed the doc generation and browser to use "ids" instead of "names" for routes and generated files.
  - Currently, "ids" are generated using dashes instead of double colons (instead of random ids). This closes issue #31.
- Added the definition and handling of canonical urls for API resources
  - One can now specify which action URL should be considered as the canonical resource href:
    - by using `canonical_path <action_name>` at the top of the resource definition class
    - See the [instances](https://github.com/rightscale/praxis/blob/master/spec/spec_app/design/resources/instances.rb) resource definition for an example.
  - With a canonical href defined, one can then both generate and parse them by using:
    - `.to_href(<named arguments hash>) => <href String>`
    - `.parse_href( <href String> ) => < named arguments hash >`. Note: The returned arguments are properly typed-coerced.
    - These helpers can be accessed from:
      - the `definition` object in the controller instance (i.e., `self.definition.to_href(id: 1). )
      - or through the class-level methods in the resource definition (i.e. `MyApiResource.parse_href("/my_resource/1")` )
- Hooked up rake tasks into the `praxis` binary for convenience. In particular
  - praxis routes [json]
  - praxis docs [browser]
  - praxis console
- Added `MediaTypeCommon` module, which contains the `identifier`, `description`, and `describe` methods formerly found in `MediaType`. This is now the module used for checking whether a given class should be included in generated documentation, or is valid for use in a `ResponseDefinition`
- Improved `Praxis::Collection.of` when used with MediaTypes
  - It will now define an inner `<media_type>::Collection` type that is an `Attributor::Collection` of the MediaType that also will include the `MediaTypeCommon` module.
  - By default, Praxis will take the identifier of the parent `MediaType` and append a `collection=true` suffix to it.
- Fixed `ResponseDefinition` Content-Type validation to properly handle parameters (i.e., "application/json;collection=true").
  - Note: For "index" type actions, this now means Praxis will properly validate any 'collection=true' parameter specified in the `ResponseDefintion` and set by the controller.
- Deprecated `MediaTypeCollection`. Please define separate classes and attributes for "collection" and "summary" uses.
- Improved code for stages
  - `setup!` is no longer called within the `run` default code of a stage
  - removed unnecessary raise error when substages are empty (while not common it can be possible, and totally valid)
- Add `Response` to supported classes in `PluginConcern`
- Fix doc generation to use `ids` for top-level types (rather than names) so they are correctly linkable.
- Doc Browser: Added support for Markdown rendering of descriptions (for resources, media_types, attributes, etc...)
- Added test framework for the doc browser. Run the tests with `grunt test` from lib/api_browser.
- Enhanced the `praxis:docs:preview` rake task with an optional port parameter
- Fixed praxis:routes rake task to support actions that do not have routes defined
- Added `:source` to `ActionDefinition` parameter descriptions with the value of either 'url' or 'query' to denote where the parameter is (typically) extracted from. Note: not currently shown in doc browser.

## 0.13.0

- Added `nodoc!` method to `ActionDefinition`, `ResourceDefinition` to hide actions and resources from the generated documentation.
- Default HTTP responses:
  - Added descriptions
  - Added 408 RequestTimeout response
- Replaced Ruport dependency in `praxis:routes` rake task with TerminalTable.
- Fixed doc browser issue when attributes defaulting to false wouldn't display the default section.
- Enhanced several logging aspects of the PraxisMapper plugin:
  - The log-level of the stats is now configurable in the plugin (see the comments [here](https://github.com/rightscale/praxis/blob/master/lib/praxis/plugins/praxis_mapper_plugin.rb) for details)
  - Added a "silence_mapper_stats" attribute in the Request objects so, actions and/or controllers can selectively skip logging stats (for example, health check controllers, etc)
  - It now logs a compact message (with the same heading) when the identity map has had no interactions.
- Added X-Cascade header support
  - Configured with boolean `praxis.x_cascade` that defaults to true.
  - When enabled, Praxis will add an 'X-Cascade: pass' header to the response when the request was not routable to an action. It is not added if the action explicitly returns a `NotFound` response.
- Fixed bug in request handling where `after` callbacks were being executed, even if the stage returned a response.
- Added a handy option to tie an action route to match any HTTP verb.
  - Simply use `any` as the verb when you define it (i.e. any '/things/:id' )
- Allow a MediaType to define a custom `links` attribute like any other.
  - This is not compatible if it also wants to use the `links` DSL.

## 0.11.2

- The Doc Browser will now not change the menu when refreshing.
- Fixes an issue where URLs in the doc browser would display JSON.
- Fixes an issue where table columns in the doc browser would be overlapping.
- Refactor Praxis Mapper plugin to be more generic.
- Update attributor dependency to 2.4.0

## 0.11.1

- Fix `Stats` plugin to handle empty `args` hashes.

## 0.11

- `MediaTypeCollection`:
  - Added support for loading `decorate`ed `Resource` associations.
- Refined and enhanced support for API versioning:
  - version DSL now can take a `using` option which specifies and array of the methods are allowed: `:header`,`:params`,`:path`(new)
    - if not specified, it will default to `using: [:header, :params]` (so that the version can be passed to the header OR the params)
  - the new `:path` option will build the action routes by prefixing the version given a common pattern (i.e., "/v1.0/...")
    - The effects of path versioning will be visible through `rake praxis:routes`
    - the default api prefix pattern is ("/v(version)/") but can changed by either
      - overriding ``Praxis::Request.path_version_prefix` and return the appropriate string prefix (i.e., by default this returns "/v")
      - or overriding `Praxis::Request.path_version_matcher` and providing the fully custom matching regexp. This regexp must have a capture (named `version`) that would return matched version value.
- Enhanced praxis generator:
  - Added a new generator (available through `praxis new app_name`) which creates a blank new app, with enough basic structure and setup to start building an API.
  - Changed the example hello world generation command. Instead of `praxis generate app_name`, it is now available through `praxis example app_name`
  - Changed the path lookup for the praxis directory (to not use installed gems, which could be multiple). [Issue #67]
- `ResourceDefinition`:
  - Added: `action_defaults` method, to define default options for actions. May be called more than once.
  - Removed: `params`, `payload`, `headers`, and `response`. Specify these inside `action_defaults` instead.
- `Application`:
  - Added `middleware` method to use Rack middleware.
- `ErrorHandler`
  - It is now possible to register the error handler class to be invoked when an uncaught exception is thrown by setting `Application#error_handler`.
  - The default error handler writes the error and backtrace into the Praxis logger, and returns an `InternalServerError` response
- Added `Praxis::Notifications` framework backed by ActiveSupport::Notifications
  - Its interface is the same as AS::Notifications (.publish, .instrument, .subscribe, and etc.)
  - Each incoming rack request is instrumented as `rack.request.all`, with a payload of `{response: response}`, where `response` is the `Response` object that will be returned to the client. Internally, Praxis subscribes to this to generate timing statistics with `Praxis::Stats`.
  - Additionally, each request that is dispatched to an action is instrumented as `praxis.request.all`, with a payload of `{request: request, response: response}`, where `response` is as above, and `request` is the `Request` object for the request.
- Added `Praxis::Stats` framework backed by `Harness` (i.e. a statsd interface)
  - Can be configured with a collector type (fake, Statsd) and an asynchronous queue + thread
  - Wraps the statsd interface: count, increment, decrement, time ...
- Added a new `decorate_docs` method to enhance generated JSON docs for actions in `ResourceDefinitions`
  - Using this hook, anybody can register a block that can change/enhance the JSON structure of generated documents for any given action
- Added a brand new Plugins architecture
  - Plugins can easily inject code in the Request, Controller, ResourceDefinition or ActionDefinition
  - Can be instances or singletons (and will be initialized correspondingly)
  - Plugins can be easily configured under a unique "config key" in the Praxis config
  - See the [Plugins](http://praxis-framework.io/reference/plugins/) section in the documentation for more information.
- Added a Plugin for using the Praxis::Mapper gem
  - Configurable through a simple `praxis_mapper.yml` file
  - Its supports several repositories (by name)
  - Each repository can be of a different type (default is sequel)
- `praxis:doc_browser` rake task now takes a port argument for specifying the port to run on, e.g. `rake praxis:doc_browser[9000]` to run on port 9000.
- Added `show_exceptions` configuration option to to control default ErrorHandler behavior.

## 0.10.0

- Avoid loading responses (and templates) lazily as they need to be registered in time
- Fix: app generator's handling of 404. [@magneland](https://github.com/magneland) [Issue #10](https://github.com/rightscale/praxis/issues/10)
- Fix: Getting started doc. [@WilliamSnyders](https://github.com/WilliamSnyders) [Issue #19](https://github.com/rightscale/praxis/issues/19)
- Controller filters can now shortcut the request lifecycle flow by returning a `Response`:
  - If a before filter returns it, both the action and the after filters will be skipped (as well as any remaining filters in the before list)
  - If an after filter returns it, any remaining after filters in the block will be skipped.
  - There is no way for the action result to skip the :after filters.
- Refactored Controller module to properly used ActiveSupprt concerns. [@jasonayre](https://github.com/jasonayre) [Issue #26](https://github.com/rightscale/praxis/issues/26)
- Separated the controller module into a Controller concern and a separable Callbacks concern
- Controller filters (i.e. callbacks) can shortcut request lifecycle by returning a Response object:
  - If a before filter returns it, both the action and the after filters will be skipped (as well as any remaining before filters)
  - If an after filter returns it, any remaining after filters in the block will be skipped.
  - There is no way for the action result to skip the :after filters.
  - Fixes [Issue #21](https://github.com/rightscale/praxis/issues/21)
- Introduced `around` filters using blocks: \* Around filters can be set wrapping any of the request stages (load, validate, action...) and might apply to only certain actions (i.e. exactly the same as the before/after filters)
  - Therefore they supports the same attributes as `before` and `after` filters. The only difference is that an around filter block will get an extra parameter with the block to call to continue the chain. \* See the [Instances](https://github.com/rightscale/praxis/blob/master/spec/spec_app/app/controllers/instances.rb) controller for examples.
- Fix: Change :created response template to take an optiona ‘location’ parameter (instead of a media_type one, since it doesn’t make sense for a 201 type response) [Issue #26](https://github.com/rightscale/praxis/issues/23)
- Make the system be more robust in error reporting when controllers do not return a String or a Response
- Fix: ValidationError not setting a Content-Type header. [Issue #39](https://github.com/rightscale/praxis/issues/19)
- Relaxed ActiveSupport version dependency (from 4 to >=3 )
- Fix: InternalServerError not setting a Content-Type header. [Issue #42](https://github.com/rightscale/praxis/issues/42)
- A few document browser improvements:
  _ Avoid showing certain internal type options (i.e. reference).
  _ Fixed type label cide to detect collections better, and differentiate between Attributor ones and MediaType ones.
  _ Tweaked \_example.html template to be much more collapsed by default, as it is not great, but makes it easier to review.
  _ Enhanced \_links.html template to use the rs-type-label, and rs-attribute-description directives. \* Small design improvements on the home page for showing routes and verbs more prominently.
- Mediatype documentation improvements:
  _ Make `Links` always list its attributes when describe (never shallow)
  _ refactored MediaTypeCollection to store a member_attribute (instead of a member_type), and report it in describe much like attributor collections do.
- `MediaTypeCollection`. See [volume_snapshot](spec/spec_app/design/media_types/volume_snapshot.rb) in the specs for an example.
  - Added `member_view` DSL to define a view that renders the collection's members with the given view.
  - Change: Now requires all views to be explicitly defined (and will not automatically use the underlying member view if it exists). To define a view for member element (wrapping it in a collection) one can use the new member_view.
  -

## 0.9 Initial release
