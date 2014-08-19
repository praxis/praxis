# Praxis [![TravisCI][travis-img-url]][travis-ci-url] 

[travis-img-url]: https://travis-ci.org/rightscale/praxis.svg?branch=master
[travis-ci-url]:https://travis-ci.org/rightscale/praxis

Praxis is a framework that takes a different approach to creating APIs, an approach that treats both designers and implementors as first class citizens and hold both their hands throughout the API building process. With Praxis you create an API by iterating through the design, review and implementation phases.

Building APIs with Praxis will result in faster developer times, and result in very precise documentation that is apt for both human (web browsable) or machine consumption (JSON spec files). A very important feature of Praxis is that while the design and implementation phases are done independently, the resulting system will still ensure that they are always consistent and enforced at all times. This enforcement will automatically hold true throughout any number of iterations of the design-review-implementation phases. You can, once
and for all, stop worrying about re-generating server code and keeping it in sync with any change to your code and or docs that you make.

## Quickstart
```bash
# Install the praxis gem
gem install praxis

# Generate a praxis application named my-app in ./my-app
praxis generate my-app

# Run it!
cd my-app
bundle
rackup
```

## Philosophy
Praxis is a practical implementation of a few guiding principles. In part:

### REST APIs should be consistent
REST APIs should follow consistent design in patterns and action semantics.
This includes software patterns for creating applications like code
organization; application patterns like logging, middleware, query filtering,
and application bootstrapping; and API routing structures and REST verb
semantics for exposed resources.

### Apps should focus on real business logic
Applications should be able to focus on application logic, avoiding most of the
boilerplate code required to build API services.

### API design should be separate from implementation
Applications should maintain separation of concerns between API design and
implementation. An API designer should be able to fully construct an API
skeleton without writing a single line of application code.

### APIs must have great documentation
It should be possible to generate consistent and detailed documentation. This
should be done by inspecting real code, to avoid relying on humans to do a good
job keeping the docs and the code in sync everytime they make code changes.

## Mailing List
Join our Google Groups for discussion, support and announcements.
* http://groups.google.com/d/forum/praxis-support (support for people using
  Praxis)
* http://groups.google.com/d/forum/praxis-announce (announcements)
* http://groups.google.com/d/forum/praxis-development (discussion about the
  development of Praxis itself)

## Contributions
Contributions to make Praxis better are welcome. Please refer to
[CONTRIBUTING](https://github.com/rightscale/praxis/blob/master/CONTRIBUTING.md)
for further details on what contributions are accepted and how to go about
contributing.

## Requirements
Praxis requires Ruby 2.1.0 or greater.

## License

This software is released under the [MIT License](http://www.opensource.org/licenses/MIT). Please see  [LICENSE](LICENSE) for further details.

Copyright (c) 2014 RightScale
