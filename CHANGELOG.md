# praxis changelog

## next

* `MediaTypeCollection`:
  * Added support fo loading  `decorate`ed `Resource` associations.
* Refined and enhanced support for API versioning:
  * version DSL now can take a `using` option which specifies and array of the methods are allowed: `:header`,`:params`,`:path`(new)
    * if not specified, it will default to `using: [:header, :params]` (so that the version can be passed to the header OR the params)
  * the new `:path` option will build the action routes by prefixing the version given a common pattern (i.e., "/v1.0/...")
    * The effects of path versioning will be visible through `rake praxis:routes`
    * the default api prefix pattern is ("/v(version)/") but can changed by either
      * overriding ``Praxis::Request.path_version_prefix` and return the appropriate string prefix (i.e., by default this returns "/v") 
      * or overriding `Praxis::Request.path_version_matcher` and providing the fully custom matching regexp. This regexp must have a capture (named `version`) that would return matched version value.

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
