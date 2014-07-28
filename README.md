# Praxis
Praxis is a light-weight web framework for building clean and consistent APIs
with minimal effort. It focuses on rapidly developing practical, REST APIs for
back-end services while minimizing necessary 'boilerplate' code.

## Quickstart
```bash
# Install the praxis gem
gem install praxis

# Generate a praxis application named my-app in ./my-app
praxis my-app

# Run it!
cd my-app
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
Contributions to make Praxis a better are welcome. Please refer to
[CONTRIBUTING](https://github.com/rightscale/praxis/blob/master/CONTRIBUTING.md)
for further details on what contributions are accepted and how to go about
contributing.

## Requirements
Praxis requires Ruby 2.1.0 or greater.

## License
Praxis is released under the [MIT License](http://www.opensource.org/licenses/MIT).
