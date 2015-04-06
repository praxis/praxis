---
layout: page
title: Media Type Collections
---

*NOTE*: This class is deprecated and will be removed in a future version of Praxis!
To future-proof your app, convert your `MediaTypeCollection`s to conform with
`Praxis::Collection` (and summary types) as described in [Media Types](../media-types/).

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