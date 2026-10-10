---
title: Scopes
layout: gem-single
name: hanami-view
---

A scope is the object that determines which methods are available to use from within the template. The [standard scope](docs::templates) provides access to template locals (exposed values), partial rendering, as well as the building of custom scopes.

With a custom scope, you can add your own behavior around a template and its particular set of locals. These, along with [parts](docs::parts), allow for most view logic to move away from templates and into classes you can reuse, refactor according to typical object oriented approaches, as well as test in isolation.

## Defining a scope class

To provide custom scope behavior, define your own scope classes in a common namespace (e.g. `Scopes`) and [configure that](docs::configuration) as your view's `scope_namespace`:

```ruby
class MyView < Hanami::View
  config.scope_namespace = Scopes
end
```

Each scope class must inherit from `Hanami::View::Scope`:

```ruby
module Scopes
  class MediaPlayer < Hanami::View::Scope
  end
end
```

## Building scopes

Build a scope by using the `#scope` method from within a template, or on a [part](docs::parts) or scope object.

```ruby
scope(:media_player)
```

Scopes can be passed their own set of locals:

```ruby
scope(:media_player, item: audio_file)
```

## Scope class resolution

Scope classes are looked up based on the configured `scope_namespace` and the name you pass to `#scope`.

So for a `scope_namespace` of `Scopes` and scope built as `:media_player`, the `Scopes::MediaPlayer` class will be looked up.

If a matching scope class cannot be found, the standard `Hanami::View::Scope` class will be used.

## Rendering partials

You can render a partial using a scope with the standard `#render` method:

```ruby
scope(:media_player, item: audio_file).render(:media_player)
```

This rendered partial will have access to all the scope's methods, as well as its locals (see below).

The scope will infer the partial name by rendering without any arguments:

```ruby
scope(:media_player, item: audio_file).render
```

This will use the scope's name for the name of the partial. In the example above, this is the equivalent of calling `#render(:media_player)`.

You can also render partials from  within your scope class' own methods:

```ruby
class MediaPlayer < Hanami::View::Scope
  def audio_player_html
    render(:audio_player)
  end
end
```

## Accessing locals

From within a scope class, or a template rendered with that scope, you can access the locals by their names.

For example, from a template:

```erb
<!-- e.g. accessing the `item` when rendered via scope(:media_player, item: audio_file).render -->
<%= item.title %>
```

Or from a custom scope class:

```ruby
class MediaPlayer < Hanami::View::Scope
  def display_title
    # `item` is a local
    "#{item.title} (#{item.duration})"
  end
end
```

You can also access the full hash of locals via `#_locals` (or `#locals` as a convenience, provided there is no local named `locals`).

This is useful for providing default values for locals that may not explicitly be passed when the scope is built:

```ruby
class MediaPlayer < Hanami::View::Scope
  def show_artwork?
    locals.fetch(:show_artwork, true)
  end
end
```

## Declaring locals

A scope class can declare the locals it takes, with defaults for the optional ones:

```ruby
class MediaPlayer < Hanami::View::Scope
  locals :audio_file, show_artwork: true
end
```

Building the scope with `scope(:media_player, ...)`, from a template or a part, then raises an `ArgumentError` for a missing local (`missing local: :audio_file for MediaPlayer`) or one the class does not declare, and fills in the defaults for the rest. The scope's methods, and the partials it renders without arguments, see the locals with their defaults. A default is one object shared by every scope built without that local, so do not mutate it.

A scope built from a part is given the part under the part's name, which follows the name it is exposed under, so declare that too. A declaring scope therefore serves parts exposed under one name.

This declares what the scope takes, not what any one partial takes, since one scope can render several partials. A partial rendered from the scope with arguments gets a new scope of the same class holding only those arguments, unchecked, so the scope's methods there see only those.

Subclasses inherit the declaration, and may replace it with their own, but cannot return to taking any locals unchecked. A class may declare its locals only once. A declaration on a view's own scope, set with `config.scope`, is not checked, since that scope's locals are the view's exposures.

## Accessing the context

In your scope classes, you can access the [context object](docs::context) as `#_context` (or `#context` as a convenience, provided there is no local named `context`).

Scopes also delegate missing methods to the context object (provided there is no local with that name).

For example:

```ruby
class MediaPlayer < Hanami::View::Scope
  def image_urls
    # item is a local, and asset_path is a method defined on the context object
    [item.image_url, asset_path("standard-media-artwork.png")]
  end
end
```

## Memoizing methods

You may choose to memoize expensive operations within a scope to ensure they only run once.

## Configuring a scope for a whole view

Aside from building custom scopes explicitly, you can also specify a scope to be used when a view renders its own template.

You can specify the scope as a direct class reference:

```ruby
class MyView < Hanami::View
  config.template = "my_view"
  config.scope = Scopes::MyView
end
```

Or if you have a scope namepace configured, you can use a symbolic name and a matching scope will be looked up:

```ruby
class MyView < Hanami::View
  config.template = "my_view"
  config.scope_namespace = Scopes
  config.scope = :my_view
end
```

## Providing a custom scope builder

To fully customize scope lookup and initialization, you can provide a replacement scope builder:

```ruby
class MyView < Hanami::View
  config.scope_builder = MyScopeBuilder
end
```

Your scope builder must conform to the following interface:

- `#initialize(namespace: nil, render_env: nil)`
- `#for_render_env(render_env)`
- `#call(name = nil, locals)`

You can also inherit from `Hanami::View::ScopeBuilder` and override any of its methods, if you want to customize just a particular aspect of the standard behavior.
