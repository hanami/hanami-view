---
title: Templates
layout: gem-single
name: hanami-view
---

Every view has a template, which is passed the values from the view’s [exposures](docs::exposures) and then used to render the view output.

Save your template in one of the `paths` [configured](docs::configuration) in your view.

Templates follow a 3-part naming scheme: `<name>.<format>.<engine>`:

- `name` matches the view’s `template` [setting](docs::configuration)
- `format` is for matching the template with the view’s format
- `engine` is the rendering engine to use with the template

An example is `index.html.slim`, which would be found for a view controller with a `name` of `"index"` and a `default_format` of `:html`. This template would be rendered with the [Slim](http://slim-lang.com) template engine.

## Template engines

hanami-view uses [Tilt](https://github.com/jeremyevans/tilt) to render its templates, and relies upon Tilt’s auto-detection of rendering engine based on the template file’s extension. However, you should explicitly `require` any engine gems that you intend to use.

Some Tilt-supplied template engines may not fully support hanami-view's features (like implicit block capturing). Your view will raise an exception, along with instructions for resolving the issue, if Tilt provides a non-compatible engine.

The currently known problematic engines are:

- Erb, which requires the [Erbse](https://github.com/apotonick/erbse) engine
- Haml, which requires the [Hamlit::Block](https://github.com/hamlit/hamlit-block) engine

## Template scope

Each template is rendered with its own _scope_, which determines the methods available within the template. The scope behavior is established by 3 things:

1. The scope’s class, which is `Hanami::View::Scope` by default, but can be changed for a template by specifying a class for the view’s [`scope` setting](docs::configuration), or for a partial rendering by using [`#scope`](docs::scopes) from within a part or scope method, or within the template itself
2. The template’s _locals_, the [exposure values](docs::exposures) decorated by their [parts](docs::parts)
3. The [context object](docs::context)

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

## Partials

The template scope provides a `#render` method, for rendering partials:

```erb
<%= render :sidebar %>
```

### Partial lookup

The template for a partial is prefixed by an underscore and searched through a series of directories, including a directory named after the current template, as well as a "shared" directory.

So for a `sidebar` partial, rendered within a `users/index.html.erb` template, the partial would be searched for at the following locations in your view's configured paths:

- `/users/index/_sidebar.html.erb`
- `/users/_sidebar.html.erb`
- `/users/shared/_sidebar.html.erb`

If a matching partial template is not found in these locations, the search is repeated in each parent directory until the view path’s root is reached, e.g.:

- `/_sidebar.html.erb`
- `/shared/_sidebar.html.erb`

### Partial scope

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
