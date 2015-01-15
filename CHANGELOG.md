# praxis changelog

## next

* The Doc Browser will now not change the menu when refreshing.
* Fixes an issue where URLs in the doc browser would display JSON.
* Fixes an issue where table columns in the doc browser would be overlapping.

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
