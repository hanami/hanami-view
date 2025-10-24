# Hanami::View

Hanami::View is a complete view rendering system that gives you everything you need to write well-factored view code.

It can be used as a standalone library or as part of the complete Hanami framework.

This README has documentation for use as a standalone library, please see the [Hanami guides Views](https://guides.hanamirb.org/views/overview/) section for assistance using it with the full Hanami framework.

## Status

[![Gem Version](https://badge.fury.io/rb/hanami-view.svg)](https://badge.fury.io/rb/hanami-view)
[![CI](https://github.com/hanami/view/actions/workflows/ci.yml/badge.svg)](https://github.com/hanami/view/actions?query=workflow%3Aci+branch%3Amain)

## Contact

* Home page: http://hanamirb.org
* Community: http://hanamirb.org/community
* Guides: https://guides.hanamirb.org
* Mailing List: http://hanamirb.org/mailing-list
* API Doc: http://rubydoc.info/gems/hanami-view
* Chat: http://chat.hanamirb.org

## Rubies

## Installation

Add this line to your application's Gemfile:

```ruby
gem "hanami-view"
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install hanami-view
```

## Usage

#### Table of contents

- [Introduction](#introduction)
- [Configuration](#configuration)
- [Injecting dependencies](#injecting-dependencies)
- [Exposures](#exposures)
- [Templates](#templates-1)
- [Parts](#parts)
- [Scopes](#scopes)
- [Context](#context)
- [Testing](#testing)


### Introduction

Use hanami-view if:

- You recognize that view code can be complex, and want to work with a system that allows you to break your view logic apart into sensible units
- You want to be able to [unit test](#testing) all aspects of your views, in complete isolation
- You want to maintain a sensible separation of concerns between the layers of functionality within your app
- You want to build and render views in any kind of context, not just when serving HTTP requests
- You're using a lightweight routing DSL like Hanami::Router, Roda, or Sinatra and you want to keep your routes clean and easy to understand (hanami-view handles the integration with your application, so all you need to provide from routes is the user-provided input params)
- Your application structure supports dependency injection as the preferred way to share behaviour between components (e.g. hanami-view fits perfectly with [dry-system](https://dry-rb.org/gems/dry-system), [dry-container](https://dry-rb.org/gems/dry-container), and [dry-auto_inject](https://dry-rb.org/gems/dry-auto_inject))

#### Concepts

hanami-view divides the responsibility of view rendering across several different components:

- The **View**, representing a view in its entirety, holding its configuration as well as any application-provided dependencies
- [**Exposures**](#exposures), defined as part of the view, declare the values that should be exposed to the template, and how they should be prepared
- [**Templates** and **partials**](#templates-1), which contain the markup, code, and logic that determine the view's output. Templates may have different **formats**, which act as differing representations of a given view
- [**Parts**](#parts), which wrap the values exposed to the template and provide a place to encapsulate view-specific behavior along with particular values
- [**Scopes**](#scopes), which offer a place to encapsulate view-specific behaviour intended for a particular _template_ and its complete set of values
- [**Context**](#context), a single object providing the baseline environment for a given rendering, with its methods made available to all templates, partials, parts, and scopes

#### Example

[Configure](#configuration) your view, accept some [dependencies](#injecting-dependencies), and define an [exposure](#exposures):

```ruby
require "hanami/view"

class ArticleView < Hanami::View
  config.paths = [File.join(__dir__, "templates")]
  config.part_namespace = Parts
  config.layout = "application"
  config.template = "articles/show"

  attr_reader :article_repo

  def initialize(article_repo:)
    @article_repo = article_repo
  end

  expose :article do |slug:|
    article_repo.by_slug(slug)
  end
end
```

Write a layout (`templates/layouts/application.html.erb`):

```erb
<html>
  <body>
    <%= yield %>
  </body>
</html>
```

And a [template](#templates-1) (`templates/articles/show.html.erb`):

```erb
<h1><%= article.title %></h1>
<p><%= article.byline_text %></p>
```

Define a [part](#parts) to provide view-specific behavior around the exposed `article` value:

```ruby
module Parts
  class Article < Hanami::View::Part
    def byline_text
      authors.map(&:name).join(", ")
    end
  end
end
```

Then `#call` your view to render the output:

```ruby
view = ArticleView.new
view.call(slug: "cheeseburger-backpack").to_s
# => "<html><body><h1>Cheeseburger Backpack</h1><p>Rebecca Sugar, Ian Jones-Quartey</p></body></html>
```

`Hanami::View#call` expects keyword arguments for input data. These arguments are handled by your [exposures](#exposures), which prepare [view parts](#parts) that are passed to your [template](#templates-1) for rendering.


### Configuration
###### ⬆️ Go to [Table of contents](#table-of-contents)

You can configure your views via class-level `config`. Basic configuration looks like this:

```ruby
class MyView < Hanami::View
  config.paths = [File.join(__dir__, "templates")]
  config.layout = "application"
  config.template = "my_view"
end
```

#### Settings

##### Templates

- **paths** (_required_): An array of directories that will be searched for all templates (templates, partials, and layouts).
- **template** (_required_): Name of the template for rendering this view. Template name should be relative to your configured view paths.
- **layout**: Name of the layout to render templates within. Layouts are found within the `layouts_dir` within your configured view paths. A false or nil value will use no layout. Defaults to `nil`.
- **layouts_dir**: Name of the directory to search for layouts (within the configured view paths). Defaults to `"layouts"`
- **default_format**: The format used when looking up template files (templates are found using a `<name>.<format>.<engine>` pattern). Defaults to `:html`.

##### Rendering environment

- **scope**: a [scope class](#scopes) to use when rendering the view's template
- **default_context**: a [context object](#context) to during rendering (if none is provided via the `context:` option when `#call`-ing the view)

##### Template engine

- **renderer_options**: a hash of options to pass to the template engine, defaults to `{default_encoding: "utf-8"}`. Template engines are provided by [Tilt](https://github.com/rtomayko/tilt); see Tilt's documentation for what options your template engine may support.
- **renderer_engine_mapping**: a hash specifying the template engine class to use for a given format, e.g. `{erb: Tilt::ErubiTemplate}`. Template engine detection is automatic based on format; use this setting only if you want to force a non-preferred engine.

#### Sharing configuration via inheritance

In an app with many views, it’s helpful to use inheritance to share common settings. Create a base view class containing your app’s default settings, and inherit from it for each individual view.

```ruby
module MyApp
  class View < Hanami::View
    # Set common configuration in the shared base view class
    config.paths = [File.join(__dir__, "templates")]
    config.layout = "application"
    config.part_namespace = View::Parts
    config.scope_namespace = View::Scopes
  end
end

module MyApp
  module Views
    class Home < MyApp::View
      # Set view-specific configuration in subclasses
      config.template = "home"
    end
  end
end
```

#### Changing configuration at render-time

Some configuration-related options can also be passed at render-time, to `Hanami::View#call`.

- **format**: Specify another format for rendering the view. This overrides the `default_format` setting.
- **context**: Provide an alternative [context object](#context) for the [template scope](#templates-1). This is helpful for providing a context object that has, for example, data specific to the current HTTP request.


### Injecting dependencies
###### ⬆️ Go to [Table of contents](#table-of-contents)

Most views will need access to other parts of your application to prepare values for the view. Since views follow the "functional object" pattern (local state for config and collaborators only, with any variable data passed to `#call`), it’s easy to use dependency injection to make your application’s objects available to your views.

To set up the injection manually, accept arguments to `#initialize` and assign them to instance variables.

```ruby
class MyView < Hanami::View
  attr_reader :user_repo

  def initialize(user_repo:)
    @user_repo = user_repo
    super()
  end

  expose :users do
    user_repo.listing
  end
end
```

Or if your app uses [dry-system](https://dry-rb.org/gems/dry-system) or [dry-auto_inject](https://dry-rb.org/gems/dry-auto_inject), this is even less work:

```ruby
# Require the auto-injector module for your app's container
require "my_app/import"

class MyView < Hanami::View
  include MyApp::Import["user_repo"]

  expose :users do
    user_repo.listing
  end
end
```


### Exposures
###### ⬆️ Go to [Table of contents](#table-of-contents)

Define _exposures_ within your view to declare and prepare the values to be passed to the template, decorated as [parts](#parts).

An exposure can take a block:

```ruby
class MyView < Hanami::View
  expose :users do
    user_repo.listing
  end
end
```

Or refer to an instance method:

```ruby
class MyView < Hanami::View
  expose :users

  private

  def users
    user_repo.listing
  end
end
```

Or allow a matching value from the input data to pass through to the view:

```ruby
class MyView < Hanami::View
  # With no matching instance method, passes the `users:` argument provided to
  # `#call` straight to the template
  expose :users
end
```

#### Accessing input data

If your exposure needs to work with input data (i.e. the arguments passed to the view’s `#call`), specify these as keyword arguments for your exposure block. Make this a _required_ keyword argument if you require the data passed to the view’s `#call`:

```ruby
class MyView < Hanami::View
  expose :users do |page:|
    user_repo.listing(page: page)
  end
end
```

The same applies to instance methods acting as exposures:

```ruby
class MyView < Hanami::View
  expose :users

  private

  def users(page:)
    user_repo.listing(page: page)
  end
end
```

##### Specifying defaults

To make input data optional, provide a default value for the keyword argument (either `nil` or something more meaningful):

```ruby
class MyView < Hanami::View
  expose :users do |page: 1|
    user_repo.listing(page: page)
  end
end
```

If your exposure passes through input data directly, use the `default:` option:

```ruby
class MyView < Hanami::View
  # With no matching instance method, passes the `users:` argument to `#call`
  # straight to the template
  expose :users, default: []
end
```

#### Accessing the context

To access the [context object](#context) from an exposure, include a `context:` keyword parameter:

```ruby
expose :articles do |context:|
  article_repo.listing_for_user(context.current_user)
end
```

#### Depending on other exposures

Sometimes you may want to prepare data for other exposures to use. You can _depend_ on another exposure by naming it as a positional argument for your exposure block or method.

```ruby
class MyView < Hanami::View::Controller
  expose :users do |page:|
    user_repo.listing(page: page)
  end

  expose :user_count do |users|
    users.to_a.length
  end
end
```

In this example, the `user_count` exposure has access to the value of the `users` value since it named the exposure as a positional argument. The `users` value is at this point will already be decorated by its [part object](#parts).

Exposure dependencies (positional arguments) and input data (keyword arguments) can also be provided together:

```ruby
expose :user_count do |users, count_title: "Admins count"|
  "#{count_title}: #{users.to_a.length}"
end
```

#### Layout exposures

Exposure values are made available only to the template by default. To make an exposure available to the layout, specify the `layout: true` option:

```ruby
expose :users, layout: true do |page:|
  user_repo.listing(page: page)
end
```

#### Private exposures

You can create _private exposures_ that are not passed to the template. This is helpful if you have an exposure that others will depend on, but is not otherwise needed in the template. Use `private_expose` for this:

```ruby
class MyView < Hanami::View::Controller
  private_expose :user_listing do
    user_repo.listing
  end

  expose :users do |user_listing|
    # does something with user_listing
  end

  expose :user_count do |user_listing|
    # also needs to work with user_listing
  end
end
```

In this example, only `users` and `user_count` will be passed to the template.

#### Undecorated exposures

You can create an exposure whose value is not decorated by a part. This may be helpful when your exposure returns a simpler "primitive" object that requires no extra behaviour, like a number or a string. To do this, pass the `decorate: false` option.

```
expose :page_number, decorate: false
```


### Templates
###### ⬆️ Go to [Table of contents](#table-of-contents)

Every view has a template, which is passed the values from the view’s [exposures](#exposures) and then used to render the view output.

Save your template in one of the `paths` [configured](#configuration) in your view.

Templates follow a 3-part naming scheme: `<name>.<format>.<engine>`:

- `name` matches the view’s `template` [setting](#configuration)
- `format` is for matching the template with the view’s format
- `engine` is the rendering engine to use with the template

An example is `index.html.slim`, which would be found for a view controller with a `name` of `"index"` and a `default_format` of `:html`. This template would be rendered with the [Slim](http://slim-lang.com) template engine.

#### Template engines

hanami-view uses [Tilt](https://github.com/rtomayko/tilt) to render its templates, and relies upon Tilt’s auto-detection of rendering engine based on the template file’s extension. However, you should explicitly `require` any engine gems that you intend to use.

Some Tilt-supplied template engines may not fully support hanami-view's features (like implicit block capturing). Your view will raise an exception, along with instructions for resolving the issue, if Tilt provides a non-compatible engine.

#### Template scope

Each template is rendered with its own _scope_, which determines the methods available within the template. The scope behavior is established by 3 things:

1. The scope’s class, which is `Hanami::View::Scope` by default, but can be changed for a template by specifying a class for the view’s [`scope` setting](#configuration), or for a partial rendering by using [`#scope`](#scopes) from within a part or scope method, or within the template itself
2. The template’s _locals_, the [exposure values](#exposures) decorated by their [parts](#parts)
3. The [context object](#context)

The template scope evaluates methods sent to it in this order:

1. The scope's own methods are all available
2. If there is a matching local, it is returned
3. If the context object responds to the method, it is called, along with any arguments passed to the method.

For example:

```erb
<!-- `#asset_path` is defined on the context object -->
<img src="<%= asset_path("header.png") %>">

<!-- `#page_title` is defined on the custom scope class -->
<h1><%= page_title %></h1>

<!-- `#users` is a local -->
<% users.each do |user| %>
  <p><%= user.name %></p>
<% end %>
```

#### Partials

The template scope provides a `#render` method, for rendering partials:

```erb
<%= render :sidebar %>
```

##### Partial lookup

The template for a partial is prefixed by an underscore and searched through a series of directories, including a directory named after the current template, as well as a "shared" directory.

So for a `sidebar` partial, rendered within a `users/index.html.erb` template, the partial would be searched for at the following locations in your view's configured paths:

- `/users/index/_sidebar.html.erb`
- `/users/_sidebar.html.erb`
- `/users/shared/_sidebar.html.erb`

If a matching partial template is not found in these locations, the search is repeated in each parent directory until the view path’s root is reached, e.g.:

- `/_sidebar.html.erb`
- `/shared/_sidebar.html.erb`

##### Partial scope

A partial called with no arguments is rendered with the same scope as its parent template. This is useful for breaking larger templates up into smaller chunks for readability. For example:

```erb
<h1>About us</h1>

<%# Split this template into 3 partials, all sharing the same scope %>
<%= render :introduction %>
<%= render :location %>
<%= render :contact_form %>
```

Otherwise, partials accept keywords arguments, which become the partial’s locals. For example:

```erb
<%= render :contact_form, form_title: "Get in touch" %>
```

The view’s context object remains part of the scope for every partial rendering, regardless of the arguments passed.


### Parts
###### ⬆️ Go to [Table of contents](#table-of-contents)

All values [exposed](#exposures) by your view are decorated and passed to your templates as _parts_, which allow encapsulation of view-specific behavior alongside your application's domain objects.

Unlike many third-party approaches to view object decoration, hanami-view's parts are fully integrated and have access to the full rendering environment, which means that anything you can do from a template, you can also do from a part. This includes accessing the context object as well as rendering partials and building scopes.

This means that much more view logic can move out of template and into parts, which makes the templates simpler and more declarative, and puts the view logic into a place where it can be reused and refactored using typical object oriented approaches, as well as tested in isolation.

#### Defining a part class

To provide custom part behavior, define your own part classes in a common namespace (e.g. `Parts`) and [configure that](#configuration) as your view's `part_namespace` Each part class must inherit from `Hanami::View::Part`.

```ruby
module Parts
  class User < Hanami::View::Part
  end
end
```

#### Part class resolution

Part classes are looked up based on each exposure's name.

So for an exposure named `:article`, the `Parts::Article` class will be looked up and used to decorate the article value.

For an exposure returning an array, the exposure's name will be singularized and each element in the array will be decorated with a matching part. Then the array _itself_ will be decorated by a matching part.

So for an exposure named `:articles`, the `Parts::Article` class will be looked up for decorating each element, and the `Parts::Articles` class will be looked up for decorating the entire array.

If a matching part class cannot be found, the standard `Hanami::View::Part` class will be used.

If your application does not use class autoloading, you should explicitly `require` your part files to ensure the classes are available.

#### Accessing the decorated value

When using a part within a template, or when defining your own part methods, you can call the decorated value's methods and the part object will pass them through (via `#method_missing`).

For example, from a template:

```erb
<!-- All the methods on the user value are still available -->
<p><%= user.name %></p>
```

Or when defining a custom part class:

```ruby
class User < Hanami::View::Part
  def display_name
    # `name` and `email` are methods on the decorated user value
    "#{name} <#{email}>"
  end
end
```

In case of naming collisions or when overriding a method, you can access the value directly via `#_value` (or `#value` as a convenience, as long the decorated value itself doesn't respond to `#value`):

```ruby
class User < Hanami::View::Part
  def name
    value.name.upcase
  end
end
```

#### String conversion

When used to output to the template, a part will use it's value `#to_s` behavior (which you can override in your part classes):

```erb
<p><%= user %></p>
```

#### Rendering partials

From a part, you can render a partial, with the part object included in the partial's own locals:

```ruby
class User < Hanami::View::Part
  def info_box
    render(:info_box)
  end
end
```

This will render an `_info_box` partial template (via the standard [partial lookup rules](#partial-lookup) with the part still available as `user`.

You can also render such partials directly within templates:

```erb
<%= user.render(:info_box) %>
```

To make the part available by another name within the partial's cope, use the `as:` option:

```erb
<%= user.render(:info_box, as: :account) %>
```

You can also provide additional locals for the partial:

```erb
<%= user.render(:info_box, as: :account, title_label: "Your account") %>
```

#### Building scopes

You may [build custom scopes](#scopes) from within a part using `#_scope` (or `#scope` as a convenience, as long as the decorated value doesn't respond to `#scope`):

```ruby
class User < Hanami::View::Part
  def info_box
    scope(:info_box, size: :large).render
  end
end
```

#### Accessing the context

In your part classes, you can access the [context object](#context) as `#_context` (or `#context` as a convenience, as long the decorated value itself doesn't respond to `#context`). Parts also delegate missing methods to the context object (provided the decorated value itself doesn't respond to the method).

For example:

```ruby
class User < Hanami::View::Part
  def avatar_url
    # asset_path is a method defined on the context object (in this case,
    # providing static asset URLs)
    value.avatar_url || asset_path("default-user-avatar.png")
  end
end
```

#### Decorating part attributes

Your values may have their own attributes that you also want decorated as view parts. Declare these using `decorate` in your own view part classes:

```ruby
class UserPart < Hanami::View::Part
  decorate :address
end
```

You can pass the same options to `decorate` as you do to [exposures](#exposures), for example:

```ruby
class UserPart < Hanami::View::Part
  decorate :address, as: :location
end
```

#### Memoizing methods

A part object lives for the entirety of a view rendering, you can memoize expensive operations to ensure they only run once.

```ruby
class User < Hanami::View::Part
  def bio_html
    @bio_html ||= rich_text_renderer.render(bio)
  end

  private

  def rich_text_renderer
    @rich_text_renderer ||= MyRenderer.new
  end
end
```

#### Custom part class resolution

When defining your exposures, use the `as:` option to specify an alternative name or class for part decoration.

For singular values:

- `expose :article, as: :story` will look up a `Parts::Story` class
- `expose :article, as: Parts::MyArticle` will use the provided class

For arrays:

- `expose :articles, as: :stories` will look up `Parts::Stories` for decorating the array, and `Parts::Story` for decorating the elements
- `expose :articles, as: [:story_collection]` will look up `Parts::StoryCollection` for decorating the array, and `Parts::Article` for decorating the elements
- `expose :articles, as: [:story_collection, :story]` will look up `Parts::StoryCollection` for decorating the array, and `Parts::Story` for decorating the elements
- For the two `as:` structures above (with the names in the array), explicit classes can be provided instead of symbols, and they'll be used for decorating their respective items

All of these examples presume a configured `part_namespace` of `Parts`.

#### Providing a custom part builder

To fully customize part decoration, you can provide a replacement part builder:

```ruby
class MyView < Hanami::View
  config.part_builder = MyPartBuilder
end
```

Your part builder must conform to the following interface:

- `#initialize(namespace: nil, render_env: nil)`
- `#for_render_env(render_env)`
- `#call(name, value, **options)`

You can also inherit from `Hanami::View::PartBuilder` and override any of its methods, if you want to customize just a particular aspect of the standard behavior.


### Scopes
###### ⬆️ Go to [Table of contents](#table-of-contents)

All values [exposed](#exposures) by your view are decorated and passed to your templates as _parts_, which allow encapsulation of view-specific behavior alongside your application's domain objects.

Unlike many third-party approaches to view object decoration, hanami-view's parts are fully integrated and have access to the full rendering environment, which means that anything you can do from a template, you can also do from a part. This includes accessing the context object as well as rendering partials and building scopes.

This means that much more view logic can move out of template and into parts, which makes the templates simpler and more declarative, and puts the view logic into a place where it can be reused and refactored using typical object oriented approaches, as well as tested in isolation.

#### Defining a part class

To provide custom part behavior, define your own part classes in a common namespace (e.g. `Parts`) and [configure that](#configuration) as your view's `part_namespace` Each part class must inherit from `Hanami::View::Part`.

```ruby
module Parts
  class User < Hanami::View::Part
  end
end
```

#### Part class resolution

Part classes are looked up based on each exposure's name.

So for an exposure named `:article`, the `Parts::Article` class will be looked up and used to decorate the article value.

For an exposure returning an array, the exposure's name will be singularized and each element in the array will be decorated with a matching part. Then the array _itself_ will be decorated by a matching part.

So for an exposure named `:articles`, the `Parts::Article` class will be looked up for decorating each element, and the `Parts::Articles` class will be looked up for decorating the entire array.

If a matching part class cannot be found, the standard `Hanami::View::Part` class will be used.

If your application does not use class autoloading, you should explicitly `require` your part files to ensure the classes are available.

#### Accessing the decorated value

When using a part within a template, or when defining your own part methods, you can call the decorated value's methods and the part object will pass them through (via `#method_missing`).

For example, from a template:

```erb
<!-- All the methods on the user value are still available -->
<p><%= user.name %></p>
```

Or when defining a custom part class:

```ruby
class User < Hanami::View::Part
  def display_name
    # `name` and `email` are methods on the decorated user value
    "#{name} <#{email}>"
  end
end
```

In case of naming collisions or when overriding a method, you can access the value directly via `#_value` (or `#value` as a convenience, as long the decorated value itself doesn't respond to `#value`):

```ruby
class User < Hanami::View::Part
  def name
    value.name.upcase
  end
end
```

#### String conversion

When used to output to the template, a part will use it's value `#to_s` behavior (which you can override in your part classes):

```erb
<p><%= user %></p>
```

#### Rendering partials

From a part, you can render a partial, with the part object included in the partial's own locals:

```ruby
class User < Hanami::View::Part
  def info_box
    render(:info_box)
  end
end
```

This will render an `_info_box` partial template (via the standard [partial lookup rules](#templates-1)) with the part still available as `user`.

You can also render such partials directly within templates:

```erb
<%= user.render(:info_box) %>
```

To make the part available by another name within the partial's cope, use the `as:` option:

```erb
<%= user.render(:info_box, as: :account) %>
```

You can also provide additional locals for the partial:

```erb
<%= user.render(:info_box, as: :account, title_label: "Your account") %>
```

#### Building scopes

You may [build custom scopes](#scopes) from within a part using `#_scope` (or `#scope` as a convenience, as long as the decorated value doesn't respond to `#scope`):

```ruby
class User < Hanami::View::Part
  def info_box
    scope(:info_box, size: :large).render
  end
end
```

#### Accessing the context

In your part classes, you can access the [context object](#context) as `#_context` (or `#context` as a convenience, as long the decorated value itself doesn't respond to `#context`). Parts also delegate missing methods to the context object (provided the decorated value itself doesn't respond to the method).

For example:

```ruby
class User < Hanami::View::Part
  def avatar_url
    # asset_path is a method defined on the context object (in this case,
    # providing static asset URLs)
    value.avatar_url || asset_path("default-user-avatar.png")
  end
end
```

#### Decorating part attributes

Your values may have their own attributes that you also want decorated as view parts. Declare these using `decorate` in your own view part classes:

```ruby
class UserPart < Hanami::View::Part
  decorate :address
end
```

You can pass the same options to `decorate` as you do to [exposures](#exposures), for example:

```ruby
class UserPart < Hanami::View::Part
  decorate :address, as: :location
end
```

#### Memoizing methods

A part object lives for the entirety of a view rendering, you can memoize expensive operations to ensure they only run once.

```ruby
class User < Hanami::View::Part
  def bio_html
    @bio_html ||= rich_text_renderer.render(bio)
  end

  private

  def rich_text_renderer
    @rich_text_renderer ||= MyRenderer.new
  end
end
```

#### Custom part class resolution

When defining your exposures, use the `as:` option to specify an alternative name or class for part decoration.

For singular values:

- `expose :article, as: :story` will look up a `Parts::Story` class
- `expose :article, as: Parts::MyArticle` will use the provided class

For arrays:

- `expose :articles, as: :stories` will look up `Parts::Stories` for decorating the array, and `Parts::Story` for decorating the elements
- `expose :articles, as: [:story_collection]` will look up `Parts::StoryCollection` for decorating the array, and `Parts::Article` for decorating the elements
- `expose :articles, as: [:story_collection, :story]` will look up `Parts::StoryCollection` for decorating the array, and `Parts::Story` for decorating the elements
- For the two `as:` structures above (with the names in the array), explicit classes can be provided instead of symbols, and they'll be used for decorating their respective items

All of these examples presume a configured `part_namespace` of `Parts`.

#### Providing a custom part builder

To fully customize part decoration, you can provide a replacement part builder:

```ruby
class MyView < Hanami::View
  config.part_builder = MyPartBuilder
end
```

Your part builder must conform to the following interface:

- `#initialize(namespace: nil, render_env: nil)`
- `#for_render_env(render_env)`
- `#call(name, value, **options)`

You can also inherit from `Hanami::View::PartBuilder` and override any of its methods, if you want to customize just a particular aspect of the standard behavior.


### Context
###### ⬆️ Go to [Table of contents](#table-of-contents)

Use a context object to provide shared facilities to every template, partial, scope, and part in a given view rendering.

A context object is helpful in holding any behaviour or data you don't want to pass around explicitly. For example:

- Data specific to the current HTTP request, like the request path and CSRF tags
- A "current user" or similar session-based object needed across multiple disparate places
- Application static assets helpers
- `content_for`-style helpers

#### Defining a context

Context classes must inherit from `Hanami::View::Context`

```ruby
class MyContext < Hanami::View::Context
end
```

#### Injecting dependencies

`Hanami::View::Context` is designed to allow dependencies to be injected into your subclasses. To do this, accept your dependencies as keyword arguments to `#initialize`, and pass all arguments through to `super`:

```ruby
class MyContext < Hanami::View::Context
  attr_reader :assets

  def initialize(assets:, **args)
    @assets = assets
    super
  end

  def asset_path(asset_name)
    assets[asset_name]
  end
end
```

If your app uses [dry-system](https://dry-rb.org/gems/dry-system) or [dry-auto_inject](https://dry-rb.org/gems/dry-auto_inject), this is even less work. dry-auto_inject works out of the box with `Hanami::View::Context`’s initializer:

```ruby
# Require the auto-injector module for your app's container
require "my_app/import"

class MyContext < Hanami::View::Context
  include MyApp::Import["assets"]

  def asset_path(asset_name)
    assets[asset_name]
  end
end
```

#### Providing the context

The default context can be `configured` for a view:

```ruby
class MyView < Hanami::View
  config.default_context = MyContext.new
end
```

Or provided at render-time, when calling a view:

```ruby
my_view.call(context: my_context)
```

This context object will override whatever has been previously configured.

When providing a context at render time, you may wish to provide a version of your context object with e.g. data specific to the current HTTP request, which is not available when configuring the view with a context.

#### Decorating context attributes

Your context may have attribute that you want decorated as [parts](#parts). Declare these using `decorate` in your context class:

```ruby
class MyContext < Hanami::View::Context
  decorate :navigation_items

  attr_reader :navigation_items

  def initialize(navigation_items:, **args)
    @navigation_items = navigation_items
    super(**args)
  end
end
```

You can pass the same options to `decorate` as you do to [exposures](#exposures), for example:

```ruby
class MyContext < Hanami::View::Context
  decorate :navigation_items, as: :menu_items

  # ...
end
```


### Context
###### ⬆️ Go to [Table of contents](#table-of-contents)

Use a context object to provide shared facilities to every template, partial, scope, and part in a given view rendering.

A context object is helpful in holding any behaviour or data you don't want to pass around explicitly. For example:

- Data specific to the current HTTP request, like the request path and CSRF tags
- A "current user" or similar session-based object needed across multiple disparate places
- Application static assets helpers
- `content_for`-style helpers

#### Defining a context

Context classes must inherit from `Hanami::View::Context`

```ruby
class MyContext < Hanami::View::Context
end
```

#### Injecting dependencies

`Hanami::View::Context` is designed to allow dependencies to be injected into your subclasses. To do this, accept your dependencies as keyword arguments to `#initialize`, and pass all arguments through to `super`:

```ruby
class MyContext < Hanami::View::Context
  attr_reader :assets

  def initialize(assets:, **args)
    @assets = assets
    super
  end

  def asset_path(asset_name)
    assets[asset_name]
  end
end
```

If your app uses [dry-system](https://dry-rb.org/gems/dry-system) or [dry-auto_inject](https://dry-rb.org/gems/dry-auto_inject), this is even less work. dry-auto_inject works out of the box with `Hanami::View::Context`’s initializer:

```ruby
# Require the auto-injector module for your app's container
require "my_app/import"

class MyContext < Hanami::View::Context
  include MyApp::Import["assets"]

  def asset_path(asset_name)
    assets[asset_name]
  end
end
```

#### Providing the context

The default context can be `configured` for a view:

```ruby
class MyView < Hanami::View
  config.default_context = MyContext.new
end
```

Or provided at render-time, when calling a view:

```ruby
my_view.call(context: my_context)
```

This context object will override whatever has been previously configured.

When providing a context at render time, you may wish to provide a version of your context object with e.g. data specific to the current HTTP request, which is not available when configuring the view with a context.

#### Decorating context attributes

Your context may have attribute that you want decorated as [parts](#parts). Declare these using `decorate` in your context class:

```ruby
class MyContext < Hanami::View::Context
  decorate :navigation_items

  attr_reader :navigation_items

  def initialize(navigation_items:, **args)
    @navigation_items = navigation_items
    super(**args)
  end
end
```

You can pass the same options to `decorate` as you do to [exposures](#exposures), for example:

```ruby
class MyContext < Hanami::View::Context
  decorate :navigation_items, as: :menu_items

  # ...
end
```

### Testing
###### ⬆️ Go to [Table of contents](#table-of-contents)

Use a context object to provide shared facilities to every template, partial, scope, and part in a given view rendering.

A context object is helpful in holding any behaviour or data you don't want to pass around explicitly. For example:

- Data specific to the current HTTP request, like the request path and CSRF tags
- A "current user" or similar session-based object needed across multiple disparate places
- Application static assets helpers
- `content_for`-style helpers

#### Defining a context

Context classes must inherit from `Hanami::View::Context`

```ruby
class MyContext < Hanami::View::Context
end
```

#### Injecting dependencies

`Hanami::View::Context` is designed to allow dependencies to be injected into your subclasses. To do this, accept your dependencies as keyword arguments to `#initialize`, and pass all arguments through to `super`:

```ruby
class MyContext < Hanami::View::Context
  attr_reader :assets

  def initialize(assets:, **args)
    @assets = assets
    super
  end

  def asset_path(asset_name)
    assets[asset_name]
  end
end
```

If your app uses [dry-system](https://dry-rb.org/gems/dry-system) or [dry-auto_inject](https://dry-rb.org/gems/dry-auto_inject), this is even less work. dry-auto_inject works out of the box with `Hanami::View::Context`’s initializer:

```ruby
# Require the auto-injector module for your app's container
require "my_app/import"

class MyContext < Hanami::View::Context
  include MyApp::Import["assets"]

  def asset_path(asset_name)
    assets[asset_name]
  end
end
```

#### Providing the context

The default context can be `configured` for a view:

```ruby
class MyView < Hanami::View
  config.default_context = MyContext.new
end
```

Or provided at render-time, when calling a view:

```ruby
my_view.call(context: my_context)
```

This context object will override whatever has been previously configured.

When providing a context at render time, you may wish to provide a version of your context object with e.g. data specific to the current HTTP request, which is not available when configuring the view with a context.

#### Decorating context attributes

Your context may have attribute that you want decorated as [parts](#parts). Declare these using `decorate` in your context class:

```ruby
class MyContext < Hanami::View::Context
  decorate :navigation_items

  attr_reader :navigation_items

  def initialize(navigation_items:, **args)
    @navigation_items = navigation_items
    super(**args)
  end
end
```

You can pass the same options to `decorate` as you do to [exposures](#exposures), for example:

```ruby
class MyContext < Hanami::View::Context
  decorate :navigation_items, as: :menu_items

  # ...
end
```

## Versioning

__Hanami::View__ uses [Semantic Versioning 2.0.0](http://semver.org)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright © 2014–2024 Hanami Team – Released under MIT License
