# Praxis [![TravisCI][travis-img-url]][travis-ci-url] [![Coverage Status][coveralls-img-url]][coveralls-url] 

[travis-img-url]: https://app.travis-ci.com/praxis/praxis.svg?branch=master
[travis-ci-url]: https://app.travis-ci.com/praxis/praxis
[coveralls-img-url]:https://coveralls.io/repos/github/praxis/praxis/badge.svg?branch=master
[coveralls-url]:https://coveralls.io/github/praxis/praxis?branch=master

A fast and highly efficient paradigm to build beautiful service APIs

Praxis is built to empower development teams with extreme productivty tools to create fast, and modern APIs that will delight their customers. Some of the salient features are:

* **Truthful & Beautiful Docs:** Automatically generate Open API 3.x documents from the actual functioning code, and rest assured they're always correct.

* **GraphQL Flexibility, REST Simplicity:** Allow customers to specify which fields they want to receive using the GraphQL syntax, but exposing them through well known REST endpoints.
* **Fast Runtime and Blazing Fast Development:** Deploy your API using one of the best Ruby performing frameworks and take advantage of an unprecedented development speed.
* **API Design-First Philosophy:** Craft and visualize your API design upfont, without writing a single line of code. Forget about implementing any of the API validations, the framework fully takes care of it from your design specification.
* **Feature Rich yet Fully Customizable:** Fully take advantage of the tons of best practices, proven methods, standards and features that the frameworks comes with, or pick and choose only the ones you want to enable.
* **Hardnened & Battle Tested:** Rest assured you'll get the advertised results as this framework has been deployed in production environments since before 2014.

## Quickstart
```bash
# Install the praxis gem
gem install praxis

# Generate and bundle a praxis application named my-app in ./my-app
praxis example my-app && cd my-app && bundle

# Run it!
rackup
```

Or check the getting started tutorial and reference docs at https://site.praxis-framework.io all that Praxis has to offer.

## Mailing List
Join our Google Groups for discussion, support and announcements.
* [praxis-support](http://groups.google.com/d/forum/praxis-support) (support for people using
  Praxis)
* [praxis-announce](http://groups.google.com/d/forum/praxis-announce) (announcements)
* [praxis-development](http://groups.google.com/d/forum/praxis-development) (discussion about the
  development of Praxis itself)

<!-- Join our slack support and general announcements channel for on-the-spot answers to your questions:
* To join our slack chat please go to: http://praxis-framework.herokuapp.com and sign in for an account.
* Once you have an account, hop onto the chat at http://praxis-framework.slack.com -->

And follow us on twitter: [@praxisapi](http://twitter.com/praxisapi)

## Contributions
Contributions to make Praxis better are welcome. Please refer to
[CONTRIBUTING](https://github.com/praxis/praxis/blob/master/CONTRIBUTING.md)
for further details on what contributions are accepted and how to go about
contributing.

## Requirements
Praxis requires Ruby 2.7.0 or greater, but it is best when used with the latest 3.x series.

## License

This software is released under the [MIT License](http://www.opensource.org/licenses/MIT). Please see  [LICENSE](LICENSE) for further details.

This framework was initially developed and used at RightScale, and was open sourced in 2014, after a few years of its production use.
