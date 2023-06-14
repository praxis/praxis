# Praxis Changelog

## next

## 2.0.pre.34
- Allow filtering, ordering and pagination to freely use any attributes (potentially deep ones) when no block for the definition is provided. When continuing to define the allowed fields from within the block, those would still be enforced.
- Added the ability to easily control the hiding/displayability of MediaType attributes in responses.
  - it introduces a :displayable custom attribute that accepts an array of opaque strings, which can represent some sort of 'privileges' required to have for it to be renderable.
  - the expander tooling now, will use such `display_attribute?` method to decide if a given attribute needs to be expanded/displayed or not.
  - The glue to all this requires defining a `display_attribute?` method in the controllers (with takes an array of string opaque privileges), which needs to return true/false to decide if a given attribute is displayable or now. This method will commonly be connected to the `authz` pieces of your app, and would look at the assigned 'privileges' of the currently logged in 'principal', and simply lookup if the required set of privileges received in the method, fall within the currently assigned ones.
- Cleanup in the OpenAPI generation for schemas, to more properly surface existing custom attributes into x-{name} attributes as well.

## 2.0.pre.33
- Better support for ordefing in newer versions of MySQL:
  * Some versions will complain on an invalid query if you use an ORDER BY component that does not have the corresponding SELECT field
- Use the newest Attributor gem, which revamps and hardnens the struct/collection definion DSL, and provides much better error messages and safety. It also
  bring the ability to define collections with `<T>[]` which is equivalent to the current `Attributor::Collection.of(<T>). For example, you can now do things
  like `String[]`, `MyMediaType[]`, etc..
- Tightened a few type comparisons throughout the framework, and built full specs for struct/collection definitions in Blueprints.
- Built config for the Appraisals gem, so we can continuously test some of our extensions against different versions of ActiveRecord as it evolves (6x and7x for now)

## 2.0.pre.32
- Spruced up the scaffolding generation, to be more configurable using a `.praxis_scaffold` file at the root, where one can specify things like
  the base module for all generated classes (`base`), the path of the models directory (`models_dir`) and the version to use (`version`). These, except the models directory can also be passed and overriden by command line arguments (and they would be saved into the config file to be usable in future invocations)
- More efficient validation of Blueprint structures
- Fix pseudo bug where the field expander capped subfields as soon as it encountered a type without explicit attributes (i.e., Hash). Instead, it allows any of the subfields to percolate through.
- OpenApi generation improvements:
  - Add global parameters for versioning (ApiVersionHeader and ApiVersionParam) appropriately if the API is versioned by them. Have actions point to these definitions by $ref
  - Expect the 'server' definition in the APIDefinition to contain url/description and 'variables' sections which might define variables in the server url

## 2.0.pre.31

- Switch the locally generated index.html file to browse the generated OpenAPI docs to use `elements` instead of `reDoc`
- Spruce up the initial Gemfile for the generated example app
- Fix Praxis::Mapper ordering code, to not prefix top level columns with the table name, as this completely confuses ActiveRecord which switches to full-on eager loading all of the associations in the top query. i.e., passing an invalid table/column name in a `references` method will trigger that (seemingly a current bug)

## 2.0.pre.30

- A few cleanup and robustness additions:
  - OpenAPI: Disable overriding a description when the schema is a ref (there are known issues with UI browsers)
  - Internal: use `_pk` in batch processor invocation instead of `id` (resources will now have a `_pk` method which defaults to `id`)
  - Bumped gemspec Ruby dependency to >=2.7 (but note, that this is just a little relaxed for older codebase, we're fully building for 3.x)
- Backwards incompatible changes:
  - Enforces property names are symbols (before strings were allowed)
  - Resource properties, using the `as:` option, are now enforced to be real association names (will not accept other resource names and unroll their dependencies)
  - Deprecated the `:through` option for a property. You can just use `as:` with a long, dot-separated association path directly.
- Enhanced ordering semantics for pagination to allow for sorting of deep associated fields:
  - Right now, you can sort by fields such as `books.author.name` as one of the sorting components (with `+` or `-` still available)
- Introduced better attribute grouping concepts, that help in defining subgroups of attributes of the same object, and allow lazy loading of only partial subsets so that one can have expensive computations on some of them, but they will never be invoked unless necessary. See MediaType.`group` and Resoruce.`property_group` explanations below.
- Introduced a 'group' stanza in MediaTypes, to specify a structure of attributes that exist in the main object, but that we want to neatly expose as a subset (instead of having them unrolled at the top):
  - You can now use things like `group subinfo do ... end` blocks, defining which attributes to group
  - Internal: Underneath, the system will create a BlueprintAttributeGroup (instead of a Struct) as a way to ensure that only the individual attributes that need to be rendered, are accessed (and not load the whole struct at once). While the behavior, to the outside, is gonna be identical to a Struct (i.e., exposes attributes as methods), this distinct object implementation is very important as it allows you to have attributes in the subgroup that are expensive to compute, and can be rest assured that they will not be accessed/computed unless they are required for rendering.
- Introduced the `property_group` stanza in resources, to indicate that a property contains a substructure of attributes, each of which must be able to be loaded only when necessary. This commonly goes hand in hand with a `group` stanza in the resource's MediaType:
  - Usage of property group requires the name of the substructure (a symbol), and the associated mediatype that contains the definition of the `group` struct, under the same name of the property.
  - Internally, this stanza, will define a normal property, and include as dependencies all of the sub attributes read from the MediaType's property, but appending the name (and `_`) to them to avoid collisions.
  - Also, it will define a method with the property name which will return a Forwarding object, which will delegate each of the attribute methods back to the original self objects. This allows the object to avoid being 'loaded' as a whole as it happens with Struct, therefore only materializing/calling the attribute that we actually need to use, selectively.
  - For example, if we have the `Book` MediaType which has a group atrribute called `subinfo` with a few attributes (like `name` and `pages`), we can use `property_group :subinfo, Book` on its domain object, so that the system will:
    - define a `subinfo` property which will depend on `subinfo_name` and `subinfo_pages`
    - define a `subinfo` method that will return a Forwarding object, that will forward `name` and `pages` methods to `subinfo_name` and `subinfo_pages` methods of the self resource.
    - with that, we just need to define our `subinfo_name` and `subinfo_page` methods in the resource (and also define property dependencies for them if we need to)

## 2.0.pre.29

- Assorted set of fixes to generate cleaner and more compliant OpenApi documents.
  - Mostly in the area of multipart generation, and requirements and nullability for OpenApi 3.0

## 2.0.pre.28

- Enhance the mapper's Resource property to allow for a couple more powerful options using the `as:` keyword:
  - `as: :self` will provide a way to map any further incoming fields on top of the already existing object. This is useful when we want to expose some properties for a resource, grouped within a sub structure, but that in reality they exist directly in the resource's underlying model (i.e., to organize the information of the model in a more structured/groupable way).
  - `as: 'association1.association2'` allows us to traverse more than 1 association, and continue applying the incoming fields under that. This is commonly used when we want to expose a relationship on a resource, which is really coming from more than a single association level depth.

## 2.0.pre.27

- Introduce a new `as:` option for resource's `property`, to indicate that the underlying association method it is connected to, has a different name.
  - This also will create a delegation function for the property name, that instead of calling the underlying association on the record, and wrapping the result with a resource instance, it will simply call the aliased method name (which is likely gonna hit the autogenerated code for that properyty, unless we have overriden it)
  - With this change, the selector generator (i.e., the thing that looks at the incoming `fields` parameters and calculates which select and includes are necessary to query all the data we need), will be able to understand this aliasing cases, and properly pass along, and continue expanding any nested fields that are under the property name (before this, and further inner fields would be not included as soon as we hit a property that didn't have that direct association underneath).

## 2.0.pre.26

- Make POST action forwarding more robust against technically malformed GET requests with no body but passing `Content-Type`. This could cause issues when using the `enable_large_params_proxy_action` DSL.

## 2.0.pre.25

- Improve surfacing of requirement attributes in Structs for OpenApi generated documentation
- Introduction of a new dsl `enable_large_params_proxy_action` for GET verb action definitions. When used, two things will happen:
  - A new POST verb equivalent action will be defined:
    - It will have a `payload` matching the shape of the original GET's params (with the exception of any param that was originally in the URL)
    - By default, the route for this new POST request is gonna have the same URL as the original GET action, but appending `/actions/<action_name>` to it. This can be customized by passing the path with the `at:` parameter of the DSL. I.e., `enable_large_params_proxy_action at: /actions/myspecialname` will change the generated path (can use the `//...` syntax to not include the prefix defined for the endpoint). NOTE: this route needs to be compatible with any params that might be defined for the URL (i.e., `:id` and such).
    - This action will be fully visible and fully documented in the API generated docs. However, it will not need to have a corresponding controller implementation since it will special-forward it to the original GET action switching the parameters for the payload.
  - Specifically, upon receiving a request to the POST equivalent action, Praxis will detect it is a special action and will:
    - use directly the original action (i.e., will do the before/after filters and call the controller's method)
    - will load the parameters for the action from the incoming payload
  - This functionality is to allow having a POST counterpart to any GET requests that require long query strings, and for which the client cannot use a payload bodies (i.e,. Browser JS clients cannot send payload on GET requests).
- Performance improvement:
  - Cache praxis associations' computation for ActiveRecord (so no communication with AR or DB happens after that)
- Performance improvement: Use OJ as the (faster) default JSON renderer.
- Introduce batch computation of resource attributes: This defines an optional DSL (`batch_computed`) to enable easier calculation of expensive attributes that can be calculated much more efficiently in group:
  - The new DSL takes an attribute name (Symbol), options and an implementation block that is able to get a list of resource instances (a hash of them, indexed by id) and perform the computation for all of them at once.
  - Defining an attribute this way, resources can be used to be much more efficiently to calculate values that can be retrieved much more efficiently in bulk, and/or that depend on other resources of the same type to do so (i.e., things that to calculate that attribute for one single resource can be greatly amortized by doing it for many).
  - The provided block to calculate the value of the attribute for a collection of resources of the same type is stored as a method inside an inner module of the resource class called BatchProcessors
  - The class level method is callable through `::BatchProcessors.<property_name>(rows_by_id: xxx)`. The rows_by_id: parameter has resource 'ids' as keys, and the resource instances themselves a values
  - By default an instance method of the same `<property_name>` name will also be created, with a default implementation that will call the `BatchProcessor.<property_name>` with only its instance id and instance, and will return only its result from it.
  - If creating the helper instance method is not desired, one can pass `with_instance_method: false` when defining the batched_computed block. This might be necessary if we want to define the method ourselves, or in cases where the resource itself has an 'id' property that is not called 'id' (in which case the implementation would not be correct as it uses the `id` property of the resource). If that's the case, disable the creation, and add your own instance method that uses the defined BatchProcessor method passing the right parameters.
  - It is also possible to query which attributes for a resource class are batch computed. This is done through .batched_attributes (which returns and array of symbol names)
  - NOTE: Defining batch_computed attributes needs to be done before finalization

## 2.0.pre.24

Assorted set of fixes and cleanup:

- better forwarding signature for query methods
- Fix the way with which to decide how to wrap an association (based on Enumerable isn't right, as Hashes are Enumerable as well). Wrapping decision
  is now made based on the association type, and not the shape of the resulting type.
- Built handling of some multivalue and/or fuzzy matching cases in filtering params
- unrestrict mustermann's dependent version
- Support options and even passing a full type (instead of a block) in signature definitions (TypedMethods for resources)

## 2.0.pre.22

- Small fix in OpenAPI doc generation, which would detect and report more output types, even if they are only defined within the
  children of anonymous types.

## 2.0.pre.22

- Introduced Resource callbacks (an includeable concern). Callbacks allow you to define methods or blocks to be executed `before`, `after` or `around` any existing method in the resource. Class-level callbacks are defined with `self.xxxxx`. These methods will be executed within the instance of the resource (i.e., in the same context of the original) and must be defined with the same parameter signature. For around methods, only blocks can be used, and to call the original (inner) one, one needs to yield.
- Introduced QueryMethods for resources (an includeable concern). QueryMethods expose handy querying methods (`.get`, `.get!`, `.all`, `.first` and `.last` ) which will reach into the underlying ORM (i.e., right now, only ActiveModelCompat is supported) to perform the desired loading of data (and subsequent wrapping of results in resource instances).
  - For ActiveRecord `.get` takes a condition hash that will translate to `.find_by`, and `.all` gets a condition hash that will translate to `.where`.
  - `.get!` is a `.get` but that will raise a `Praxis::Mapper::ResourceNotFound` exception if nothing was found.
  - There is an `.including(<spec>)` function that can be use to preload the underlying associations. I.e., the `<spec>` argument will translate to `.includes(<spec>)` in ActiveRecord.
- Introduced method signatures and validations for resources.
  - One can define a method signature with the `signature(<name>)` stanza, passing a block defining Attributor parameters. For instance method signatures, the `<name>` is just a symbol with the name of the method. For class level methods use a string, and prepend `self.` to it (i.e., `self.create`).
  - Signatures can only work for methods that either have a single argument (taken as a whole hash), or that have only keyword arguments (i.e., no mixed args and kwargs). It would be basically impossible to validate that combo against an Attributor Struct.
  - The calls to typed methods will be intercepted (using an around callback), and the incoming parameters will be validated against the Attributor Struct defined in the siguature, coerced if necessary and passed onto the original method. If the incoming parameters fail validation, a `IncompatibleTypeForMethodArguments` exception will be thrown.

## 2.0.pre.21

- Fix nullable attribute in OpenApi generation

## 2.0.pre.20

- Changed the behavior of dev-mode when validate_responses. Now they return a 500 status code (instead of a 400) but with the same validation error format body.
  - validate_responses is meant to catch the application returning non-compliant responses for development only. As such, a 500 is much more appropriate and clear, as the validation is done on the behavior of the server, and not on the information sent by the client (i.e., it is a server problem, not reacting the way the API is defined)
- Introduced a method to reload a Resouce (.reload), which will clear the memoized values and call record.reload as well
- Open API Generation enhancements:
  - Fixed type discovery (where some types wouldn't be included in the output)
  - Changed the generation to output named types into components, and use `$ref` to point to them whenever appropriate
  - Report nullable attributes

## 2.0.pre.19

- Introduced a new DSL for the `FilteringParams` type that allows filters for common attributes in your Media Types:
  - The new `any` DSL allows you to define which final leaf attribute to always allow, and with which operators and/or fuzzy restrictions.
  - For example, you can add `any updated_at, using: ['>','<']` which would allow the type to accept filters like `updated_at>2000-01-01`, or any existing nested fields like `posts.comments.updated_at>2000-01-01`
  - Note that the path of attributes passed in, will still need to exist and will be validated. Also, you still need to make sure that you have the right `filters_mapping` defined in your resources.
- Changed `filters_mapping` to allow implicitly any filter path that is a valid representation of existing columns and associations. I.e., you do not have to explicitly define long nested filters that correspond to the same underlying path of associations and columns.

## 2.0.pre.18

- Upgraded to newest Attributor, which cleans up the required: true semantics to only work on keys, and introduces null: true for nullability of values (independent from presence of keys or not)
- Fixed a selector generator bug that would occur when using deep nested resource dependencies as strings 'foo.bar.baz.bam'. In this cases only partial tracking of relationships would be built, which could cause to not fully eager load DB queries.

## 2.0.pre.17

- Changed the Parameter Filtering to use left outer joins (and extra conditions), to allow for the proper results when OR clauses are involved in certain configurations.
- Built support for allowing filtering directly on associations using `!` and `!!` operators. This allows to filter results where
  there are no associated rows (`!!`) or if there are some associated rows (`!`)
- Allow implicit definition of `filters_mapping` for filter names that match top-level associations of the model (i.e., like we do for the columns)

## 2.0.pre.16

- Updated `Resource.property` signature to only accept known named arguments (`dependencies` and `though` at this time) to spare anyone else from going insane wondering why their `depednencies` aren't working.
- Fixed issue with Filtering Params, that occurred with using the ! or !! operators on String-typed fields.

## 2.0.pre.14

- More encoding/decoding robustness for filters.
  - Specs for how to encode filters are now properly defined by:
    - The "value" of the filters query string needs to be URI encoded (like any other query string value). This encoding is subject to the normal rules, and therefore "could" leave some of the URI unreserved characters (i.e., 'markers') unencoded depending on the client (Section 2.2 of https://tools.ietf.org/html/rfc2396).
    - The "values" for any of the conditions in the contents of the filters, however, will need to be properly "escaped" as well (prior to URL-encoding the whole syntax string itself like described above). This means that any match value needs to ensure that it has (at least) "(",")","|","&" and "," escaped as they are reserved characters for the filter expression syntax. For example, if I want to search for a name with value "Rocket&(Pants)", I need to first compose the syntax by: "name=<escaped Rocket&(Pants)>, which is "name=Rocket%26%28Pants%29" and then, just URI encode that query string value for the filters parameter in the URL like any other. For example: "filters=name%3DRocket%2526%2528Pants%2529"
    - When using a multi-match (csv-separated) list of values, you need to escape each of the values as well, leaving the 'comma' unescape, as that's part of the syntax. Then uri-encode it all for the filters query string parameter value like above.
  - Now, one can properly differentiate between fuzzy query prefix/postfix, and the literal data to search for (which can be or include '\*'). Report that multi-matches (i.e., csv separated values for a single field, which translate into "IN" clauses) is not allowed if fuzzy matches are received (need to use multiple OR clauses for it).

## 2.0.pre.13

- Fix filters parser regression, which would incorrectly decode url-encoded values

## 2.0.pre.12

- Rebuilt API filters to support a much richer syntax. One can now use ANDs and ORs (with ANDs having order precedence), as well as group them with parenthesis. The same individual filter operands are supported. For example: 'email=_@gmail.com&(friends.first_name=Joe_,Patty|friends.last_name=Smith)

## 2.0.pre.11

- Remove MapperPlugin's `set_selectors` (made `selector_generator` lazy instead), and ensure it includes the rendering extensions to the Controllers. Less things to configure if you opt into the Mapper way.
- Built scaffolding generator for quickly creating a new API endpoint in the praxis binary (it builds endpoint+mediatype+controller+resource at one, with useful base code and comments)
- Dropped support for Ruby 2.4 and 2.5 as some of the newest dependent gems are dropping it as well.
- Simplify filters_mapping definition, by not requiring to define same-name mappings if the underlying model has an attribute with the same exact name. i.e., a `name: :name` entry is not necessary if the model has a `:name` attribute.

## 2.0.pre.10

- Simple, but pervasive breaking change: Rename `ResourceDefinition` to `EndpointDefinition` (but same functionality).
- Remove all deprecated features (and raise error describing it's not supported yet)
- Remove `Links` and `LinkBuilder`. Those seem unnecessary from a Framework point of view as they aren't clear most
  applications would benefit from it. Applications can choose to add that functionality on their own if so desire.
- Rebuilt app generators: for new empty app, and example app.
- Updated default layout to match new naming structure and more concepts commonly necessary for normal applications.
- Completely removed the native Praxis API documentation browser in lieu of OpenAPI 3.x standards, and reDoc.
- Remove dependency from praxis-blueprints, as simplified subset of its code has now been included in this repo:
  - no more views for mediatypes. A default fieldset will be automatically defined which will be the default set of attributes to render with. This default fieldset will only contain simple direct attributes (i.e., non blueprint/mediatype attributes). One can override the default by explicitly defining one using the `default_fieldset` DSL, similar to how views were defined before.
- Folded the pagination/ordering extensions to activate within the `build_query` method of the mapper plugin extension. This way all the field selection, filtering and pagination/ordering will kick in automatically when that plugin is included.

## 2.0.pre.9

- Refined OpenAPI doc generation to output only non-null attributes in the InfoObject.
- Fixed filtering params validation to properly allow null values for the "!" and "!!" operators

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
