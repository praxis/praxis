# praxis changelog

## next

* Overhauled traits: they're now represented by a `Trait` class, which are created from `ApiDefinition#trait`.
  * `ApiDefinition#describe` will also include details of the defined traits.
  * `ResourceDefinition#describe` and `ActionDefinition#describe` will also include the names of the used traits.
  * *Note*: this may break some existing trait use cases, as they are now more-defined in their behavior, rather than simply stored blocks that are `instance_eval`-ed on the target.
* Deprecated `ResourceDefinition.routing`. Use `ResourceDefinition.prefix` to define resource-level route prefixes instead.
* Significantly refactored route generation.
  * The `base_path` property defined in `ApiDefinition#info` will now appear in the routing paths 'base' (instead of simply being used for documentation purposes). 
    *Note*: unlike other info at that level, a global (unversioned) `base_path` is *not* overriden by specific version, rather the specific version's path is appended to the global path.
  * Any prefixes set on a `ResourceDefinition` or inside a `routing` block of an ActionDefinition are now additive. For example:
    * Setting a "/myresource" prefix in a "MyResource" definition, and setting a "/myaction" prefix within an action of that resource definition will result in a route containing the following segments ".../myresource/myaction...".
    * Prefixes can be equally set by including `Traits`, which will follow exactly the same additive rules.
  * To break the additive nature of the prefixes one can use a couple of different options:
    * Define the action route path with "//" to make it absolute, i.e. a path like "//people" would not include any defined prefix.
    * Explicitly clear the prefix by setting the prefix to `''` or `'//'`.
* Added `base_params` to `ApiDefinition#info` as a way to share common action params
  * `base_params` may be defined for a specific Api version, which will make sharing params across all Resource definitions of that version)
  * or `base_params` may be defined in the Global Api section, which will make the parameters shared across all actions of all defined Api versions.


## 0.15.0

* Fixed handling of no app or design file groups defined in application layout.
* Handled and added warning message for doc generation task when no routing block is defined for an action.  
* Improved `link` method in `MediaType` attribute definition to support inheriting the type from the `:using` option if if that specifies an attribute. For example: `link :posts, using: :posts_summary` would use the type of the `:posts_summary` attribute.
* Fixed generated `Links` accessors to properly load the returned value.
* Added `MediaTypeIdentifier` class to parse and manipulate Content-Type headers and Praxis::MediaType identifiers.
* Created a registry for media type handlers that parse and generate document bodies with formats other than JSON.
  * Given a structured-data response, Praxis will convert it to JSON, XML or other formats based on the handler indicated by its Content-Type.
  * Given a request, Praxis will use the handler indicated by its Content-Type header to parse the body into structured data.
* Fixed bug allowing "praxis new" to work when Praxis is installed as a system (non-bundled) gem. 
* Fixed doc generation code for custom types
* Hardened Multipart type loading

## 0.14.0

* Adds features for customizing and exporting the Doc browser, namely the following changes:
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
* First pass at describing (and doc-generating) API global information
  * Inside a `Praxis::ApiDefinition.define` block one can now specify a few things about the API by using:
    * info("1.0") `<block>` - Which will apply to a particular version only
    * info `<block>` - Which will be inherited by any existing API version
    * The current pieces of information that can be defined in the block are: `name`, `title`, `description` and `basepath`. See [this](https://github.com/rightscale/praxis/blob/master/spec/spec_app/design/api.rb) for details
  * NOTE: This information is output to the JSON files, BUT not used in the doc browser yet.
* Changed the doc generation and browser to use "ids" instead of "names" for routes and generated files.
  * Currently, "ids" are generated using dashes instead of double colons (instead of random ids). This closes issue #31.
* Added the definition and handling of canonical urls for API resources
  * One can now specify which action URL should be considered as the canonical resource href:
    * by using `canonical_path <action_name>` at the top of the resource definition class
    * See the [instances](https://github.com/rightscale/praxis/blob/master/spec/spec_app/design/resources/instances.rb) resource definition for an example.
  * With a canonical href defined, one can then both generate and parse them by using:
    * `.to_href(<named arguments hash>)  =>  <href String>`
    * `.parse_href( <href String> )  => < named arguments hash >`. Note: The returned arguments are properly typed-coerced.
    * These helpers can be accessed from:
      * the `definition` object in the controller instance (i.e., `self.definition.to_href(id: 1). )
      * or through the class-level methods in the resource definition (i.e. `MyApiResource.parse_href("/my_resource/1")` )
* Hooked up rake tasks into the `praxis` binary for convenience. In particular
  * praxis routes [json]
  * praxis docs [browser]
  * praxis console
* Added `MediaTypeCommon` module, which contains the `identifier`, `description`, and `describe` methods formerly found in `MediaType`. This is now the module used for checking whether a given class should be included in generated documentation, or is valid for use in a `ResponseDefinition`
* Improved `Praxis::Collection.of` when used with MediaTypes
  * It will now define an inner `<media_type>::Collection` type that is an `Attributor::Collection` of the MediaType that also will include the `MediaTypeCommon` module.
  * By default, Praxis will take the identifier of the parent `MediaType` and append a `collection=true` suffix to it.
* Fixed `ResponseDefinition` Content-Type validation to properly handle parameters (i.e., "application/json;collection=true").
  * Note: For "index" type actions, this now means Praxis will properly validate any 'collection=true' parameter specified in the `ResponseDefintion` and set by the controller.
* Deprecated `MediaTypeCollection`. Please define separate classes and attributes for "collection" and "summary" uses.
* Improved code for stages
  * `setup!` is no longer called within the `run` default code of a stage
  * removed unnecessary raise error when substages are empty (while not common it can be possible, and totally valid)
* Add `Response` to supported classes in `PluginConcern`
* Fix doc generation to use `ids` for top-level types (rather than names) so they are correctly linkable.
* Doc Browser: Added support for Markdown rendering of descriptions (for resources, media_types, attributes, etc...)
* Added test framework for the doc browser. Run the tests with `grunt test` from lib/api_browser.
* Enhanced the `praxis:docs:preview` rake task with an optional port parameter
* Fixed praxis:routes rake task to support actions that do not have routes defined
* Added `:source` to `ActionDefinition` parameter descriptions with the value of either 'url' or 'query' to denote where the parameter is (typically) extracted from. Note: not currently shown in doc browser.

## 0.13.0
* Added `nodoc!` method to `ActionDefinition`, `ResourceDefinition` to hide actions and resources from the generated documentation.
* Default HTTP responses:
  * Added descriptions
  * Added 408 RequestTimeout response
* Replaced Ruport dependency in `praxis:routes` rake task with TerminalTable.
* Fixed doc browser issue when attributes defaulting to false wouldn't display the default section.
* Enhanced several logging aspects of the PraxisMapper plugin:
  * The log-level of the stats is now configurable in the plugin (see the comments [here](https://github.com/rightscale/praxis/blob/master/lib/praxis/plugins/praxis_mapper_plugin.rb) for details)
  * Added a "silence_mapper_stats" attribute in the Request objects so, actions and/or controllers can selectively skip logging stats (for example, health check controllers, etc)
  * It now logs a compact message (with the same heading) when the identity map has had no interactions.
* Added X-Cascade header support
  * Configured with boolean `praxis.x_cascade` that defaults to true.
  * When enabled, Praxis will add an 'X-Cascade: pass' header to the response when the request was not routable to an action. It is not added if the action explicitly returns a `NotFound` response.
* Fixed bug in request handling where `after` callbacks were being executed, even if the stage returned a response.
* Added a handy option to tie an action route to match any HTTP verb.
  * Simply use `any` as the verb when you define it (i.e. any '/things/:id' )
* Allow a MediaType to define a custom `links` attribute like any other.
  * This is not compatible if it also wants to use the `links` DSL.



## 0.11.2

* The Doc Browser will now not change the menu when refreshing.
* Fixes an issue where URLs in the doc browser would display JSON.
* Fixes an issue where table columns in the doc browser would be overlapping.
* Refactor Praxis Mapper plugin to be more generic.
* Update attributor dependency to 2.4.0

## 0.11.1

* Fix `Stats` plugin to handle empty `args` hashes.

## 0.11

* `MediaTypeCollection`:
  * Added support for loading  `decorate`ed `Resource` associations.
* Refined and enhanced support for API versioning:
  * version DSL now can take a `using` option which specifies and array of the methods are allowed: `:header`,`:params`,`:path`(new)
    * if not specified, it will default to `using: [:header, :params]` (so that the version can be passed to the header OR the params)
  * the new `:path` option will build the action routes by prefixing the version given a common pattern (i.e., "/v1.0/...")
    * The effects of path versioning will be visible through `rake praxis:routes`
    * the default api prefix pattern is ("/v(version)/") but can changed by either
      * overriding ``Praxis::Request.path_version_prefix` and return the appropriate string prefix (i.e., by default this returns "/v")
      * or overriding `Praxis::Request.path_version_matcher` and providing the fully custom matching regexp. This regexp must have a capture (named `version`) that would return matched version value.
* Enhanced praxis generator:
  * Added a new generator (available through `praxis new app_name`) which creates a blank new app, with enough basic structure and setup to start building an API.
  * Changed the example hello world generation command. Instead of `praxis generate app_name`, it is now available through `praxis example app_name`
  * Changed the path lookup for the praxis directory (to not use installed gems, which could be multiple). [Issue #67]
* `ResourceDefinition`:
  * Added: `action_defaults` method, to define default options for actions. May be called more than once.
  * Removed: `params`, `payload`, `headers`, and `response`. Specify these inside `action_defaults` instead.
* `Application`:
  * Added `middleware` method to use Rack middleware.
* `ErrorHandler`
  * It is now possible to register the error handler class to be invoked when an uncaught exception is thrown by setting `Application#error_handler`.
  * The default error handler writes the error and backtrace into the Praxis logger, and returns an `InternalServerError` response
* Added `Praxis::Notifications` framework backed by ActiveSupport::Notifications
  * Its interface is the same as AS::Notifications (.publish, .instrument, .subscribe, and etc.)
  * Each incoming rack request is instrumented as `rack.request.all`, with a payload of `{response: response}`, where `response` is the `Response` object that will be returned to the client. Internally, Praxis subscribes to this to generate timing statistics with `Praxis::Stats`.
  * Additionally, each request that is dispatched to an action is instrumented as `praxis.request.all`, with a payload of `{request: request, response: response}`, where `response` is as above, and `request` is the `Request` object for the request.
* Added `Praxis::Stats` framework backed by `Harness` (i.e. a statsd interface)
  * Can be configured with a collector type (fake, Statsd) and an asynchronous queue + thread
  * Wraps the statsd interface: count, increment, decrement, time ...
* Added a new `decorate_docs` method to enhance generated JSON docs for actions in `ResourceDefinitions`
  * Using this hook, anybody can register a block that can change/enhance the JSON structure of generated documents for any given action
* Added a brand new Plugins architecture
  * Plugins can easily inject code in the Request, Controller, ResourceDefinition or ActionDefinition
  * Can be instances or singletons (and will be initialized correspondingly)
  * Plugins can be easily configured under a unique "config key" in the Praxis config
  * See the [Plugins](http://praxis-framework.io/reference/plugins/) section in the documentation for more information.
* Added a Plugin for using the Praxis::Mapper gem
  * Configurable through a simple `praxis_mapper.yml` file
  * Its supports several repositories (by name)
  * Each repository can be of a different type (default is sequel)
* `praxis:doc_browser` rake task now takes a port argument for specifying the port to run on, e.g. `rake praxis:doc_browser[9000]` to run on port 9000.
* Added `show_exceptions` configuration option to to control default ErrorHandler behavior.

## 0.10.0

* Avoid loading responses (and templates) lazily as they need to be registered in time
* Fix: app generator's handling of 404. [@magneland](https://github.com/magneland) [Issue #10](https://github.com/rightscale/praxis/issues/10)
* Fix: Getting started doc. [@WilliamSnyders](https://github.com/WilliamSnyders) [Issue #19](https://github.com/rightscale/praxis/issues/19)
* Controller filters can now shortcut the request lifecycle flow by returning a `Response`:
  * If a before filter returns it, both the action and the after filters will be skipped (as well as any remaining filters in the before list)
  * If an after filter returns it, any remaining after filters in the block will be skipped.
  * There is no way for the action result to skip the :after filters.
* Refactored Controller module to properly used ActiveSupprt concerns. [@jasonayre](https://github.com/jasonayre) [Issue #26](https://github.com/rightscale/praxis/issues/26)
* Separated the controller module into a Controller concern and a separable Callbacks concern
* Controller filters (i.e. callbacks) can shortcut request lifecycle by returning a Response object:
  * If a before filter returns it, both the action and the after filters will be skipped (as well as any remaining before filters)
  * If an after filter returns it, any remaining after filters in the block will be skipped.
  * There is no way for the action result to skip the :after filters.
  * Fixes [Issue #21](https://github.com/rightscale/praxis/issues/21)
* Introduced `around` filters using blocks:
	* Around filters can be set wrapping any of the request stages (load, validate, action...) and might apply to only certain actions (i.e. exactly the same as the before/after filters)
  * Therefore they supports the same attributes as `before` and `after` filters. The only difference is that an around filter block will get an extra parameter with the block to call to continue the chain.
	* See the [Instances](https://github.com/rightscale/praxis/blob/master/spec/spec_app/app/controllers/instances.rb) controller for examples.
* Fix: Change :created response template to take an optiona ‘location’ parameter (instead of a media_type one, since it doesn’t make sense for a 201 type response) [Issue #26](https://github.com/rightscale/praxis/issues/23)
* Make the system be more robust in error reporting when controllers do not return a String or a Response
* Fix: ValidationError not setting a Content-Type header. [Issue #39](https://github.com/rightscale/praxis/issues/19)
* Relaxed ActiveSupport version dependency (from 4 to >=3 )
* Fix: InternalServerError not setting a Content-Type header. [Issue #42](https://github.com/rightscale/praxis/issues/42)
* A few document browser improvements:
	* Avoid showing certain internal type options (i.e. reference).
	* Fixed type label cide to detect collections better, and differentiate between Attributor ones and MediaType ones.
	* Tweaked _example.html template to be much more collapsed by default, as it is not great, but makes it easier to review.
	* Enhanced _links.html template to use the rs-type-label, and rs-attribute-description directives.
	* Small design improvements on the home page for showing routes and verbs more prominently.
* Mediatype documentation improvements:
	* Make `Links` always list its attributes when describe (never shallow)
	* refactored MediaTypeCollection to store a member_attribute (instead of a member_type), and report it in describe much like attributor collections do.
* `MediaTypeCollection`. See [volume_snapshot](spec/spec_app/design/media_types/volume_snapshot.rb) in the specs for an example.
  * Added `member_view` DSL to define a view that renders the collection's members with the given view.
  * Change: Now requires all views to be explicitly defined (and will not automatically use the underlying member view if it exists). To define a view for member element (wrapping it in a collection) one can use the new member_view.
  *


## 0.9 Initial release
