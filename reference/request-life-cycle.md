---
layout: page
title: Request Life Cycle
---
Praxis processes each incoming request by funneling them through a pipeline of
stages. Stages are execution points during the servicing of a request, which
could themselves contain a set of sub-stages. Each registered stage has a
unique name and is connected to the other stages in a well-known order.

Praxis allows applications to 'hook into' any of those existing stages through
`before` and `after` callbacks and provides facilities to create or alter the
pipeline.

Note: while stages in the request lifecycle might behave similarly to bootstrap
stages, they perform a different role. Request life cycle stages define the
processing path for every incoming request, while bootstrapping stages define
the execution order when the application first boots.

Praxis comes out of the box with the following stage pipeline:

![Request Life Cycle Diagram]({{ site.baseurl }}/public/images/praxis_request_life_cycle_diagram.svg)

## Request Loading Stage (`:load_request`)

The request loading stage is used to retrieve all the necessary information
from the incoming HTTP request so that it is ready for processing.

This involves:

- parsing the parameters from the URI captures
- retrieving any parameters from query string
- retrieving the paylod contents
- retrieving the incoming headers

All of these, without performing any parsing or type coercion: simply gathering
the low-level arguments in one place.

Note: Strictly speaking retrieving the query string params involves some
form-encoding parsing, but it still does not involve any type coercion.

## Validation Stage (`:validate`)

During the Validate stage, Praxis will gather the raw data retrieved from the
loading stage and will:

* load them (read: coerce if necessary) into the proper structures as defined
  in your resource definitions for the action that this request is serving.
* validate them based on the same resource definitions.

These two tasks are done for data corresponding to headers, parameters and
payload. Any errors while loading the data into the right types, or validating
their integrity will cause Praxis to abort the pipeline and return an error
response to the end user indicating the exact problem (or problems) that were
encountered about the incoming data.

In particular, the Validation stage is composed of two sub-stages.

### Validate headers and params stage (`:headers_and_params`)

First, this stage will load the headers and the parameters. If all loaded fine
they will both be validated in the same order.

Note that separating headers+params from the payload validation makes it
impossible to have conditional requirements for headers or parameters that
depend on payload values.

### Validate payload stage (`:payload`)

Then this stage will load the incoming payload and then validate its integrity
after that.

Note that because the payload is validated after the headers and params, it is
completely possible to use conditional requirements based on their (loaded)
values.

## Action stage(`:action`)

Once the incoming request has been loaded and validated, the next step is to
deliver it to the controller action that will service it.

The request enters the Action stage at the point when the controller action is
invoked. This is the stage where the application will do its logic.

## Response Stage (`:response`)

The Response stage is entered when the control returns from the controller
action. The responsibility of this action is to inspect the returned value
(usually a response instance) and perform the necessary steps to unpack it and
send it back to the client.

## Hooking Into the Request Life Cycle

There are two types of hooks you can use to run a block of code during the
life cycle of a request. You can register a callback to be run either `before`
or `after` any of the available stages.

Installing callbacks is done directly from your controller. Just use the class
DSL methods `before` and `after`. These methods take the name of the stage to
hook into, a list of options, and a callback block.

The only option supported at the time of this writing is `actions`, which
allows the caller to restrict the callback to a set of named actions. Passing
no `actions` option is logically equivalent to passing every possible action.
More options for callbacks might be introduced in the future.

To install your hook before or after a substage, add the second stage name
after the first. If you completely omit the stage name, Praxis will default to
the `action` stage because that's the most common use case.

Here are some examples of how to register callbacks:

{% highlight ruby %}
  before :action, actions: [:show] do
    puts "Will print before invoking the controller method, for show action only"
  end

  before actions: [:show] do
    puts "Omiting the :action parameter!"
    puts "This is equivalent to the callback above"
  end

  after :validate, :payload do |controller|
    puts "Will print after validating the payload for any action"
  end

  after :validate, :payload, actions: [:create] do |controller|
    puts "Will print after validating the payload for create only"
  end

  after :validate do
    put "Will print after the headers and payload substages' after callbacks"
  end
end
{% endhighlight %}

There is really no difference between `after :validate` and `before :action`
since they are subsequent stages. Semantically, however, you should register
the callback based on what stage you depend on, and not on neighboring stages.
Otherwise, your code might stop functioning when the pipeline order is changed.
