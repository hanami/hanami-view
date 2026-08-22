---
title: Configuration
layout: gem-single
name: hanami-view
---

You can configure your views via class-level `config`. Basic configuration looks like this:

```ruby
class MyView < Hanami::View
  config.paths = [File.join(__dir__, "templates")]
  config.layout = "application"
  config.template = "my_view"
end
```

## Settings

### Templates

- **paths** (_required_): An array of directories that will be searched for all templates (templates, partials, and layouts).
- **template** (_required_): Name of the template for rendering this view. Template name should be relative to your configured view paths.
- **layout**: Name of the layout to render templates within. Layouts are found within the `layouts_dir` within your configured view paths. A false or nil value will use no layout. Defaults to `nil`.
- **layouts_dir**: Name of the directory to search for layouts (within the configured view paths). Defaults to `"layouts"`
- **default_format**: The format used when looking up template files (templates are found using a `<name>.<format>.<engine>` pattern). Defaults to `:html`.

### Rendering environment

- **scope**: a [scope class](docs::scopes) to use when rendering the view's template
- **default_context**: a [context object](docs::context) to during rendering (if none is provided via the `context:` option when `#call`-ing the view)

### Template engine

- **renderer_options**: a hash of options to pass to the template engine, defaults to `{default_encoding: "utf-8"}`. Template engines are provided by [Tilt](https://github.com/jeremyevans/tilt); see Tilt's documentation for what options your template engine may support.
- **renderer_engine_mapping**: a hash specifying the template engine class to use for a given format, e.g. `{erb: Tilt::ErubiTemplate}`. Template engine detection is automatic based on format; use this setting only if you want to force a non-preferred engine.

## Sharing configuration via inheritance

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

## Changing configuration at render-time

Some configuration-related options can also be passed at render-time, to `Hanami::View#call`.

- **format**: Specify another format for rendering the view. This overrides the `default_format` setting.
- **context**: Provide an alternative [context object](docs::context) for the [template scope](docs::templates). This is helpful for providing a context object that has, for example, data specific to the current HTTP request.
