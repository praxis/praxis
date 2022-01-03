# Praxis [![TravisCI][travis-img-url]][travis-ci-url] [![Coverage Status][coveralls-img-url]][coveralls-url] 

[//]: # ( COMMENTED OUT UNTIL GEMNASIUM CAN SEE THE REPOS: [![Dependency Status][gemnasium-img-url]][gemnasium-url])


[travis-img-url]: https://app.travis-ci.com/praxis/praxis.svg?branch=master
[travis-ci-url]: https://app.travis-ci.com/praxis/praxis
[coveralls-img-url]:https://coveralls.io/repos/github/praxis/praxis/badge.svg?branch=master
[coveralls-url]:https://coveralls.io/github/praxis/praxis?branch=master
[gemnasium-img-url]:https://gemnasium.com/praxis/praxis.svg
[gemnasium-url]:https://gemnasium.com/praxis/praxis

Praxis is a framework for both _designing_ and _implementing_ APIs.

An important part of the framework is geared towards the _design_ aspect of building an API. This functionality empowers architects with tools to design every last aspect of their API, resulting in a complete, web-browsable documentation, which includes automatic generation of examples for resources, parameters, headers, etc...as well as requests and responses for the supported encodings. The design process is iterative, and flows from defining new resources, parameters, etc...to reviewing the resulting docs (usually with some of the potential clients of the API), back to updating the design based on feedback, or expanding it with more resources. The design language (i.e. DSL) of Praxis follows a clean 'ruby-type-syntax' and its final outcome is to generates an output that is both a set of schema documents as well as a web-based API browser (driven by those schemas). This allows Praxis to design APIs that can potentially be implemented in any language.

Another important part of the framework is geared towards helping in the _implementation_ of the API service. In particular, Praxis provides help to Ruby developers for building a service conforming to the designed API. Aside from Ruby there is also sister-project called [Goa](http://goa.design/) that assists in implementing Praxis-like design API using Golang. Since the API design generates schema files very similar in nature to other API document formats like (Swagger, Google Discovery, RAML, etc...) supporting other implementation languages could be easily accomplished in the future by building converters to/from them.

The part of the framework that helps with the ruby service implementation takes an approach that is different from other existing ruby (micro)frameworks such as [Grape](http://www.ruby-grape.org), [Sinatra](https://github.com/sinatra/sinatra), [Scorched](http://scorchedrb.com/), [Lotus](http://lotusrb.org/) or even [RailsAPI](https://github.com/rails-api/rails-api) (now part of Rails). Instead of being developer-centric, it takes an integrated approach treating both designers and implementors as first class citizens throughout the complete API building process. With Praxis you create an API by iterating through the design, review and implementation phases. While Praxis can help Ruby developers in a lot of aspects involved in building a service, the framework is completely componentized as to allow developers to pick and choose which parts to use, which ones not to use, and which other technologies to integrate with. The framework provides help in many areas, for example: all aspects of request and response validation, automatic type-coercion, consistent error-responses, routing and url generation, advanced template/media-type definition and rendering, domain-modeling, optional database ORM (for high-perfomance large datasets), DB integration (with an efficient identityMap), a plugin and extensible framework to easily hook into, available integrations such as newrelic, statsd, etc...

There is a long list of benefits that come from using Praxis. From those, here are a couple of the salient themes:
* Designing APIs with Praxis result in a very precise, consistent and beautiful API documentation that it is apt for both human (web browsable) or machine consumption (JSON spec files).
* Building Ruby APIs with Praxis will result in much faster developer times, and more importantly with a resulting service that will ensure that its implementation is always consistent with its design, and it is enforced at all times.

## Quickstart
```bash
# Install the praxis gem
gem install praxis

# Generate a praxis application named my-app in ./my-app
praxis example my-app

# Run it!
cd my-app
bundle
rackup
```

Or better yet, checkout a simple, but functional [blog example app](https://github.com/praxis/praxis-example-app) which showcases a few of the main design and implementation aspects that Praxis has to offer.


## Mailing List
Join our Google Groups for discussion, support and announcements.
* [praxis-support](http://groups.google.com/d/forum/praxis-support) (support for people using
  Praxis)
* [praxis-announce](http://groups.google.com/d/forum/praxis-announce) (announcements)
* [praxis-development](http://groups.google.com/d/forum/praxis-development) (discussion about the
  development of Praxis itself)

Join our slack support and general announcements channel for on-the-spot answers to your questions:
* To join our slack chat please go to: http://praxis-framework.herokuapp.com and sign in for an account.
* Once you have an account, hop onto the chat at http://praxis-framework.slack.com

And follow us on twitter: [@praxisapi](http://twitter.com/praxisapi)

## Contributions
Contributions to make Praxis better are welcome. Please refer to
[CONTRIBUTING](https://github.com/praxis/praxis/blob/master/CONTRIBUTING.md)
for further details on what contributions are accepted and how to go about
contributing.

## Requirements
Praxis requires Ruby 2.1.0 or greater.

## License

This software is released under the [MIT License](http://www.opensource.org/licenses/MIT). Please see  [LICENSE](LICENSE) for further details.

Copyright (c) 2014 RightScale
