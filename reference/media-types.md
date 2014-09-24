---
layout: page
title: Media Types
---
Media types provide the structural representations of API resources. They also
contain a set of views with which you can use to render them. To define a media
type for a resource, create a class that derives from `Praxis::MediaType`,
define its attributes within the `attributes` section, and declare one or more
named `views` detailing the subset of the attributes to include. A media type
can also have a human-readable description as well as an associated Internet
media type identifier string.

Here's an example of a simple media type that describes a few attributes for a
hypothetical Blog API resource. It also defines a couple of views for it, one
called `default`, which displays the common attributes of a Blog, and another
called `link` which only includes the `href` attribute, and can be
used when rendering links to Blogs.

{% highlight ruby %}
class Blog < Praxis::MediaType
  description 'A Blog API resource represents...'
  identifier 'application/vnd.acme.blog'

  attributes do
    attribute :id, Integer
    attribute :href, String
    attribute :owner, Person
    attribute :subject, String
    attribute :locale do
      attribute :language, String
      attribute :country, String
    end
  end

  view :default do
    attribute :id
    attribute :owner, view: :compact
    attribute :subject
    attribute :locale
  end

  view :link do
    attribute :href
  end
end
{% endhighlight %}

Once a media type is defined within your application, you can use it to wrap a
compatible data object holding resource data, and render it using any of the
available views. A compatible object must respond to the method names matching
the media type attribute names, and return sub-objects that are compatible with
the types defined in the media type. Praxis renders media types into `Hash`
structures to achieve format-independence.  These rendered hash structures can
be formatted in your application using the desired wire encoding (JSON, XML, or
any other type you might need).

Here are two examples of how to render a blog_object using the `Blog` media
type: one using its `default` view and another using its `link` view:

{% highlight ruby %}
Blog.render(blog_object, view: :default)
=> {
 'id' : 123,
 'owner' : { ...an owner hash rendered with its :compact view...},
 'subject' : 'First post',
 'locale' : { 'language': 'en', 'country': 'us' }
}


Blog.render(blog_object, view: :link)
=> { 'href' : '/blogs/123' }
{% endhighlight %}

In this example, your `blog_object` must return:

{% highlight bash %}
+-----------+---------------------------------------------+
| Method    | Return value                                |
|-----------+---------------------------------------------|
| `id`      | integer                                     |
| `owner`   | object compatible with a Person media type  |
| `subject` | String                                      |
| `locale`  | object compatible with the locale structure |
| `href`    | String                                      |
+-----------+---------------------------------------------+
{% endhighlight %}

Praxis provides a lot of help in managing resource objects and linking them to
data sources (including databases) by integrating with the
[Praxis::Mapper](https://rubygems.org/gems/praxis-mapper) gem.

Also, Praxis allows you to generate compatible objects using the `.example`
feature of MediaType classes. Using this `.example` feature you can create
random instances of compatible objects without any extra effort, which is great
to simulate returning data objects when testing controller responses without
requiring any data source access. There is also some help available for
creating realistic examples for your test cases. See more [examples](#examples)
at the end of this document.

## Description

You can specify a description for the media type using the `description`
method. This description string is just for human consumption and is only used
by Praxis when generating the API documentation. Longer descriptions might use
heredoc or line escaping instead of a single-line string.

{% highlight ruby %}
class Blog < Praxis::MediaType
  description <<-eos
    This is a sample blog.
    Which requires a much longer an elaborate description to be written.
  eos
end
{% endhighlight %}

## Identifier

The media type identifier method allows you to associate an Internet media type
string with the MediaType definition. Internet media types can be very general
like 'application/json' or specific like 'application/vnd.acme.blog':

{% highlight ruby %}
class Blog < Praxis::MediaType
  identifier 'application/vnd.acme.blog'
end
{% endhighlight %}

## Attributes

The attributes section of the media type describes the full structure of the
resource representation. It describes the superset of all possible attributes
that can appear in any view that can be rendered.

The `attributes` method expects a block of attribute definitions:

{% highlight ruby %}
class Blog < Praxis::MediaType
  attributes do
    attribute :id, Integer
    attribute :href, String,        regexp: %r{/blogs/\d+}
    attribute :owner, Person,       description: 'Owner of this Blog'
    attribute :subject, String
    attribute :created_at, DateTime
    attribute :visibility, String,  values: ['public','private']
  end
end
{% endhighlight %}

Each attribute has a name, type, description and other specific configuration
options: allowed values, format, examples, etc. While some options, such as
`description` and `values` are always available for any attribute, different
attribute types support type-specific options: `min`/`max` values for Integers,
`regexp` for Strings, etc.

To read more about supported types and defining a complex and rich structures,
take a look at the [Attributor](https://rubygems.org/gems/attributor) gem and
other Praxis media type examples.

## View

A view describes which of the media type attributes should be exposed when that
view is rendered.

Each view has a unique name, and there can be as many views in a media type as
you like. Defining a view requires a block that lists the attribute names it
should include. Each included attribute can also take an optional parameter
that defines the view name to use when rendering that specific attribute. A
view option is only available when the type of the attribute is a MediaType
itself. If no view is specified, a view named `default` is used. Non-MediaType
attributes don't support views, so Praxis just renders them by calling `dump`.

{% highlight ruby %}
class Blog < Praxis::MediaType
  attributes do
    attribute :id, Integer
    attribute :href, String
    attribute :owner, Person
    attribute :subject, String
    attribute :created_at, DateTime
    attribute :locale do
      attribute :language, String
      attribute :country, String
    end
    attribute :blog_entries, Attributor::Collection.of(BlogEntry)
  end

  view :default do
    attribute :id
    attribute :owner
    attribute :locale
  end

  view :full do
    attribute :id
    attribute :owner, view: :expanded
    attribute :subject
    attribute :created_at
    attribute :blog_entries
  end
end
{% endhighlight %}

The `full` view above will render all its attributes using their `default`
views, except the `owner` attribute, which will be rendered using an
`expanded` view. In order for this to work, the Person media type needs to have
an `expanded` view defined, detailing what attributes to include.

As a corollary, all media types should include a `default` view, as this is the
default view used for rendering.

To include an attribute that has sub-attributes in a view, it is enough to list
its top level name. All of its sub-attributes will follow. For example, the
above `default` view includes the `locale` attribute, which will cause its
`language` and `country` sub-attributes to be rendered.

## Links

Praxis provides a special helper for crafting media types that refer to other
resources. In particular, it allows the use of the special `links` DSL within
the attributes block, where you can list related references. For example:

{% highlight ruby %}
class Blog < Praxis::MediaType
  identifier 'application/json'

  attributes do
    attribute :id, Integer
    attribute :href, String
    attribute :owner, Person
    attribute :subject, String
    attribute :created_at, DateTime
    attribute :blog_entries, Attributor::Collection.of(BlogEntry)

    links do
      link :owner
      link :blog_entries
    end
  end

  view :default do
    attribute :id
    attribute :subject
    attribute :links
  end

  view :full do
    attribute :id
    attribute :owner
    attribute :subject
    atttibute :blog_entries
  end
end
{% endhighlight %}

The main difference between the top-level attributes and the attributes within
the `links` block is that when Praxis renders the views, it will default to
using the `link` view. That is, instead of using the `default` view when no
view specified, it will render the target attribute using its `link` view. For
this to work, the attribute must be a media type itself, and must define a
`link` view.

You can think about the "links" DSL as a way to:

- group links within a 'links' substructure
- automatically render their elements using the `link` view

### Embedding vs. linking

Rendering a Blog media type using the `full` view defined above, will result in
embedding two fully rendered media types plus all the other regular attributes
like `id`, `subject`. The `owner` attribute embeds a Person media type
rendered using its `default` view, and the `blog_entries` attribute embeds an
array of BlogEntries, each of them rendered with the `default` view. The goal
of providing the `full` view is that it directly embeds the whole
representation of related resources. This is the snippet of how the `full`
rendered view will look:

{% highlight javascript %}
{
  id: 1
  subject: 'This is the Subject'
  owner: { ...a big owner hash rendered with its :default view...},
  blog_entries: [
    { id: 1, blog_text: 'This is the start of my first blog...' , owner: { ...} },
    { id: 2, blog_text: 'This is my second blog entry...', owner: { ...} }
  ]
}
{% endhighlight %}

Sometimes it is convenient to provide a lot of embedded information in an API
response as in the example above. This could save the client extra API calls to
retrieve that information later on. But in practice, you don't want to include
too much unnecessary information in your responses. So it is pretty common to
include only links to embedded information instead. This is exactly what
including `links` in your view will do for you.

This is what the Blog's `default` view renders:

{% highlight javascript %}
{
  id: 1
  subject: 'This is the Subject'
  links: {
    blog_entries: [
      { href: '/blog_entries/1' },
      { href: '/blog_entries/2' }
    ],
    owner: { href: '/people/3' }
  }
}
{% endhighlight %}

Rendering the `default` view for a Blog does not include the `owner` or
`blog_entries` as top level attributes. Instead, the `default` view includes
them inside the `links` attribute. So they will both be rendered using their
`link` views, which by convention will include a small subset of attributes,
perhaps just the href attribute like the example above. While this works well
for single related members, returning an array of objects with one `href` each
is not exactly what you might want for related collections. What you typically
want is to return a single collection href that, if followed, can provide the
contents of the related collection. In the next sections, we'll cover this in
more detail.

### Customizing links

So far, our examples have only shown that the `link` DSL takes a name attribute
which should match an existing and previously-defined attribute. But there are
three different ways to use the `link` stanza:

* Provide the name of an existing top-level attribute, like in the examples
  above. Using this method, there is no need to specify which associated media
  type the link will point to because that can be inferred from the top level
  attribute's type: `link :owner` will use the `Person` type.
* Explicitly include both the relationship name as well as
  the target MediaType to use. This allows you to link to a related resource,
  which might not be listed in the top-level attributes (or one that exists,
  but for which you want to use a custom MediaType instead): `link
  :latest_entry, BlogEntry` when there is no `:latest_entry` attribute defined
* Include a `using` option to tell Praxis which method name to use to retrieve
  the data for the link (see the next section for details): `link :super,
  Person, using: :manager` which uses the `manager` method rather than the
  `super` method

### Defining a link with the `using` option

When rendering an attribute, a media type retrieves the value from its
underlying object by calling a method of the same name on that object.  For
example, when rendering the `owner` attribute, the system will call the
`owner` method on the underlying object to retrieve the raw data.

There are cases, however, in which the name of the link relationship does not
necessarily correspond to the existing object's methods. There are other cases
in which you may want to use a relationship name that cannot be easily used as
a Ruby method. In this case, you can use the `using` modifier in the `link` DSL
to specify the name of the method to call instead.

Suppose that in the Blogs media type definition example, you want to get the
href for the owner, but you want to call it 'blogger' instead of 'owner'.
You can do this via the `using` clause:

{% highlight ruby %}
links do
  link :blogger, Person, using: :owner
end
{% endhighlight %}

This results in links that look like this:

{% highlight javascript %}
{
  links: {
    blogger: { href: '/people/123' }
  }
}
{% endhighlight %}

Note: Technically speaking, the `using` modifier refers to the method name of
the object that the MediaType wraps, not a method of the MediaType instance.
In the example above, `using: :owner` only works because we know that the
underlying object has that method available.  If that method were not available
it would never be able to render its `owner` attribute. We could have used
`using: :foobar` in the example above, as long as the underlying data object
responds to `foobar`.

## Collections

Praxis media types can declare attributes that are ordered collections of other
media types or other Attributor types.

### Attributor::Collection

An Attributor::Collection is a way to embed a collection of another Attributor
type. For example, you may want a collection of tag strings to be an attribute
of your blog media type:

{% highlight ruby %}
class Blog < Praxis::MediaType
  attributes do
    attribute :id, Integer
    attribute :tags, Attributor::Collection.of(String)
  end

  view :default do
    attribute :id
    attribute :tags
  end
end
{% endhighlight %}

Praxis expects to find a method named `tags` on the underlying object which
must return an array of strings. And when you render this media type, Praxis
will render them as an array of Strings.

Read more about Attributor and Attributor collections in the [attributor README
file](https://github.com/rightscale/attributor/blob/master/README.md).

### Praxis::MediaTypeCollection

Praxis::MediaTypeCollection is a special media type for collections of objects
rather than single objects. Just like a regular Praxis::MediaType, you can
declare attributes and views and render them. When populated with members, a
```Praxis::MediaTypeCollection``` is enumerable.

Also like other media types, you can embed a Praxis::MediaTypeCollection within
another media type.  For instance, a blog may have many posts and you may want
a view for your Blog media type that embeds all of a Blog's posts. You may also
want a view with aggregate information about the Posts collection instead. For
example the total number of posts or a list of all the Blog's authors. It's
also possible that you don't want to embed any information about actual posts,
but you do want to link to them.

With Praxis, you can do all of this by creating a media type for your
collection and defining the appropriate aggregate attributes, and corresponding
views.  Let's take a look at the following example, where we create an inner
```Collection``` class inside the ```Post``` media_type class:

{% highlight ruby %}
class Post < Praxis::MediaType
  attributes do
    attribute :id, Integer
    attribute :title, String
    attribute :content, String
  end

  view :default do
    attribute :id
    attribute :title
    attribute :content
  end

  class Collection < Praxis::MediaTypeCollection
    member_type Post

    attributes do
      attribute :href, String
      attribute :count, Integer
      attribute :authors, Attributor::Collection.of(String)
    end

    view :link do
      attribute :href
    end

    view :aggregate do
      attribute :href
      attribute :count
      attribute :authors
    end
  end
end
{% endhighlight %}

This Post media type has some attributes you'd expect on a blog post, and its
default view renders all of them. There is also a ```Post::Collection``` media
type.  The collection has its own attributes that refer to properties of the
collection itself rather than properties of the collection's members.

This new collection media type is a first class media type like any other,
except collection media types reference the type of members that the collection
contains.  In this case, the ```Post::Collection``` media type has ```Post```
as its member_type.  Like any other media_type, rendering a
```MediaTypeCollection``` will use the views you have defined in it. 

It is often the case that a media_type collection just wants to render itself
as a simple array wrapping its containing members. For this reason, Praxis
adds an additional DSL method to media_type collections called `member_view`. 
Here is an example of how to use it:

{% highlight ruby %}
member_view :members, using: :default
{% endhighlight %}

Adding the above statement to our ```Post::Collection``` media_type 
will create a new view called `:members`. Rendering this generates an array 
containing the existing members rendered using their `:default` view:

{% highlight javascript %}
[
  { id: 1, title: 'Title1', content: 'This is some text' },
  { id: 2, title: 'Title2', content: 'And some more' },
  { id: 3, title: 'Title3', content: 'Lorem ipsum' }
]
{% endhighlight %}


Defining collections as inner classes within the related member_type has the
advantage that can be used from other media types. Below are some examples of a
`Blog` resource that refers to the `Post` collection in various ways.

#### Embedding full collection contents

It is possible to directly embed every `Post` into its `Blog`. In this example,
when Praxis renders the view `default` for a `Blog`, it locates the
`Collection` media type you defined for `Post`, and looks for a default view.
If there is a default view directly on the collection, Praxis renders it. Since
there isn't one, Praxis will iterate the members of the collection, each one a
`Post` media type, and render them all using the default view for `Post`.

Either `Post::Collection` or `Post` must have a `default` view in this case.

{% highlight ruby %}
class Blog < Praxis::MediaType
  attributes do
    attribute :id, Integer
    attribute :posts, Post::Collection
  end

  view :default do
    attribute :id
    attribute :posts
  end
end
{% endhighlight %}

#### Embedding views of collections

You might not want to embed every single post in a `Blog` view. Instead, you
might opt to embed aggregate information about the blog's `Post` collection.
We can achieve that by rendering the `posts` with the `aggregate` view defined
above.

{% highlight ruby %}
class Blog < Praxis::MediaType
  attributes do
    attribute :id, Integer
    attribute :posts, Post::Collection
  end

  view :default do
    attribute :id
    attribute :posts, view: :aggregate
  end
end
{% endhighlight %}

Make sure the underlying object for the collection appropriately responds to
`href`, `authors`, and `count`.

#### Embedding just a link

You may want a view that merely links to a collection. That means rendering a
very simple collection view, one that contains only the link. In the
`Post::Collection` example, use the `link` view.

## Examples

Praxis provides tools to automatically generate example object values that will
respond to each and every attribute name of a media type and will return an
object that responds to the correct methods of their defined type, including
when the attribute type is another media type.

The values of the generated example attributes will also conform to
specifications like default values, regexp, etc.

Please see [Praxis::Mapper](https://rubygems.org/gems/praxis-mapper) and
[Attributor](https://rubygems.org/gems/attributor) for more on generating
example objects.
