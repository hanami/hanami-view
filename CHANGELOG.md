# Hanami::View

View layer for Hanami

## v2.3.0 - 2025-11-12

## v2.3.0.beta2 - 2025-10-17

### Changed

- Drop support for Ruby 3.1

## v2.3.0.beta1 - 2025-10-03

## v2.2.1 - 2025-03-17

### Fixed

- Allow multiple named scopes to be built in a single rendering (via a fix to internal scope class cache keys) (@swilgosz in #253)

## v2.2.0 - 2024-11-05

## v2.2.0.rc1 - 2024-10-29

## v2.2.0.beta2 - 2024-09-25

## v2.2.0.beta1 - 2024-07-16

### Changed

- Drop support for Ruby 3.0

## v2.1.0 - 2024-02-27

## v2.1.0.rc3 - 2024-02-16

### Changed
- [Tim Riley] Remove unneeded concurrent-ruby gem dependency.

## v2.1.0.rc2 - 2023-11-08

### Changed
- [Tim Riley] Remove `LayoutNotFoundError` and raise `TemplateNotFoundError` for all kinds of missing templates, including layouts.

## v2.1.0.rc1 - 2023-11-01

### Fixed
- [Tim Riley] Include methods from helper modules as public (#242)
Replace `module_function` with `extend self` to allow helper methods to remain directly usable on their modules, but to also let those methods remain public when the module is included in a class.
This will allow an intermediary `helpers` object to be created for view parts (inside full Hanami apps) to access the standard helpers.

## v2.1.0.beta2 - 2023-10-04

### Added
- [Luca Guidi] Add `Hanami::View::Rendered#match?`, `#match`, and `#include?` to make it more specs friendly.
- [Philip Arndt] Make `Hanami::View#call` to accept `layout:` keyword argument to specify the layout to use during the rendering.

## v2.1.0.beta1 - 2023-06-29

### Added
- [Tim Riley] Introduce new ERB engine, `Hanami::View::ERB`, now used by default for ERB templates;
  the erbse gem is no longer a requirement (#226)
- [Tim Riley] Introduce `Hanami::View::HTML::SafeString`, returned when calling `String#html_safe`,
  also introduced via a `Hanami::View::HTML::StringExtensions` module prepended onto `String`. (#226)
- [Tim Riley] Auto-escape HTML based on whether it is `#html_safe?` in ERB, Haml and Slim templates (#226)
- [Tim Riley] Add `part_class` and `scope_class` settings, used by the standard `part_builder` and
  `scope_builder` as the default class to use when no value-specific part or scope classes can be
  found. These settings default to `Hanami::View::Part` and `Hanami::View::Scope` respectively (#227)
- [Tim Riley] Introduce `Hanami::View::Helpers::EscapeHelper`, `Hanami::View::Helpers::TagHelper`,
  `Hanami::View::Helpers::LinkToHelper`, `Hanami::View::Helpers::NumberFormattingHelper`. These
  helper modules may optionally be mixed into your Part and Scope classes to provide additional
  conveniences when authoring your views. To do this by default, create your own
  `Hanaim::View::Part` and `Hanami::View::Scope` subclasses that include these modules, and then
  configure these as the `part_class` and `scope_class` for your views. (#229)

### Changed
- [Tim Riley] Use Zeitwerk for code loading; you should now require `require "hanami/view"` just
  once (#233)
- [Tim Riley] Change `Context` interface: custom context subclasses now have complete control over
  their `#initialize` (no longer need to receive `**options` or call `super`); though any mutable
  ivars should be duped in a custom `#initialize_copy` as required. (#223)
- [Tim Riley] Change `PartBuilder` and `ScopeBuilder` interfaces to consist of static methods only (#223)
- [Tim Riley] Finalize the view class config when calling `.new` for the first time (#223)
- [Tim Riley] Consolidate all internal caches to a single `View.cache` (#223)
- [Tim Riley] [Internal] Various refactorings to improve rendering performance (#223)

## v2.0.0.alpha8 - 2022-05-19

### Added
- [Tim Riley] Access a hash of template locals via accessing `locals` inside any template

### Changed
- [Tim Riley] Removed automatic integration of `Hanami::View` subclasses with their surrounding Hanami application. View base classes within Hanami apps should inherit from `Hanami::Application::View` instead.

## v2.0.0.alpha7 - 2022-03-08

### Added
- [Luca Guidi] Automatically inject the app's `settings` and `assets` components (if present) into instances of `Hanami::View::ApplicationContext`
- [Luca Guidi] Temporarily added to `Hanami::View::ApplicationContext` the `#content_for`, `#current_path` `#csrf_token` helpers, ported from the hanami-2-application-template. Some of those helpers will be moved to `hanami-helpers` gem in a later release.

### Changed
- [Sean Collins] For views within an Hanami application, changed default location for templates from "web/templates" to "templates"
- [Luca Guidi] For views within an Hanami application, the default `part_namespace` is now `"view/parts"` (previously `"views/parts"`)

## Fixed
- [Luca Guidi] Application-level configuration is now applied to `Hanami::View` subclasses, no matter how deep their inheritance chain (e.g. app base view -> slice base view -> slice view)

## v2.0.0.alpha6 - 2022-02-10
### Added
- [Luca Guidi] Official support for Ruby: MRI 3.0 and 3.1

### Changed
- [Luca Guidi] Drop support for Ruby: MRI 2.3, 2.4, 2.5, 2.6, and 2.7.

## v2.0.0.alpha5 - 2022-01-12
### Added
- [Marc Busqué] Automatically provide access to Hanami application routes helper as `routes` in default application view context (`Hanami::View::ApplicationContext`)

## v2.0.0.alpha3 - 2021-11-09
### Added
- [Pablo Vicente] Raise `LayoutNotFoundError` exception with friendlier, more specific error message when layouts cannot be found

### Changed
- [Tim Riley] (Internal) Updated settings to use updated dry-configurable `setting` 0.13.0 API

## v2.0.0.alpha2 - 2021-05-04
### Changed
- [Tim Riley] Replaced entire gem with dry-view (now renamed to hanami-view). See [dry-view's documentation](https://dry-rb.org/gems/dry-view/) for its capabilities and [the dry-view changelog](CHANGELOG.dry-view.md) for its history.

## v1.3.1 - 2019-01-18
### Added
- [Luca Guidi] Official support for Ruby: MRI 2.6
- [Luca Guidi] Support `bundler` 2.0+

## v1.3.0 - 2018-10-24

## v1.3.0.beta1 - 2018-08-08
### Fixed
- [Ferdinand Niedermann] Ensure to set `:disable_escape` option only for Slim and don't let Tilt to emit a warning for other template engines.
- [glaszig] Ensure partial rendering to respect `format` overriding

## v1.2.1 - 2018-10-16
### Added
- [Luca Guidi] Introduced new, backward compatible, signature to render a layout for testing purposes (eg. `ApplicationLayout.new({ format: :html }, "contents").render`)

### Fixed
- [Luca Guidi] Ensure layout to be rendered when using HAML 5
- [Luca Guidi] Ensure to raise `NoMethodError` when an unknown method is invoked by a view/template

## v1.2.0 - 2018-04-06

## v1.2.0.rc2 - 2018-04-06

## v1.2.0.rc1 - 2018-03-30

## v1.2.0.beta2 - 2018-03-23

## v1.2.0.beta1 - 2018-02-28

## v1.1.2 - 2018-04-10
### Fixed
- [Luca Guidi] Ensure to be able to use `exposures` even when they aren't duplicable objects

## v1.1.1 - 2018-02-27
### Added
- [Luca Guidi] Official support for Ruby: MRI 2.5

### Fixed
- [Alfonso Uceda] Ensure that `exposures` are properly overwritten for partials when `locals:` option is used

## v1.1.0 - 2017-10-25

## v1.1.0.rc1 - 2017-10-16

## v1.1.0.beta3 - 2017-10-04

## v1.1.0.beta2 - 2017-10-03
### Added
- [Luca Guidi] Added `Hanami::Layout#local` to safely access locals from layouts

## v1.1.0.beta1 - 2017-08-11
### Fixed
- [yjukaku] Raise `Hanami::View::UnknownRenderTypeError` when an argument different from `:template` or `:partial` is passed to `render`

## v1.0.1 - 2017-08-04
### Added
- [Luca Guidi] Compatibility with `haml` 5.0

## v1.0.0 - 2017-04-06

## v1.0.0.rc1 - 2017-03-31

## v1.0.0.beta2 - 2017-03-17
### Changed
- [Luca Guidi] Remove deprecated `Hanami::View::Rendering::LayoutScope#content`

## v1.0.0.beta1 - 2017-02-14
### Added
- [Luca Guidi] Official support for Ruby: MRI 2.4
- [Vladimir Dralo] Allow `View#initialize` to splat keyword arguments

## v0.8.0 - 2016-11-15
### Fixed
- [Luca Guidi] Ensure `Rendering::NullLocal` to work with HAML templates

### Changed
- [Luca Guidi] Official support for Ruby: MRI 2.3+ and JRuby 9.1.5.0+

## v0.7.0 - 2016-07-22
### Added
- [Luca Guidi] Introduced `#local` for views, layouts and templates. It allows to safely access locals without raising errors in case the referenced local is missing.

### Fixed
- [nessur] Find the correct partial in case of deeply nested templates.
- [Marcello Rocha] Ensure `Hanami::Presenter` to respect method visibility of wrapped object.
- [Luca Guidi] Ensure to use new registry when loading the framework

### Changed
– [Luca Guidi] Drop support for Ruby 2.0 and 2.1. Official support for JRuby 9.0.5.0+.
– [Luca Guidi] Deprecate `#content` in favor of `#local`.

## v0.6.1 - 2016-02-05
### Changed
- [Steve Hook] Preload partial templates in order to boost performances for partials rendering (2x faster)

### Fixed
- [Luca Guidi] Disable Slim autoescape to use `Hanami::View`'s feature

## v0.6.0 - 2016-01-22
### Changed
- [Luca Guidi] Renamed the project

## v0.5.0 - 2016-01-12
### Added
- [Luca Guidi] Added `Lotus::View::Configuration#default_encoding` to set the encoding for templates

### Fixed
- [Luca Guidi] Let exceptions to be raised as they occur in rendering context. This fixes misleading backtraces for exceptions.
- [Martin Rubi] Raise a `Lotus::View::MissingTemplateError` when rendering a missing partial from a template
- [Luca Guidi] Fix for `template.erb is not valid US-ASCII (Encoding::InvalidByteSequenceError)` when system encoding is not set

### Changed
- [Liam Dawson] Introduced `Lotus::View::Error` and let all the framework exceptions to inherit from it.

## v0.4.4 - 2015-09-30
### Added
- [Luca Guidi] Autoescape for layout helpers.

## v0.4.3 - 2015-07-10
### Fixed
- [Farrel Lifson] Force partial finder to be explicit when to templates have the same name.

## v0.4.2 - 2015-06-23
### Fixed
- [Tom Kadwill] Ensure views to use methods defined by the associated layout.

## v0.4.1 - 2015-05-22
### Added
- [Luca Guidi] Introduced `#content` to render optional contents in a different context (eg. a view sets a page specific javascript in the application template footer).

## v0.4.0 - 2015-03-23
### Changed
- [Luca Guidi] Autoescape concrete and virtual methods from presenters
- [Luca Guidi] Autoescape concrete and virtual methods from views

### Fixed
- [Tom Kadwill] Improve error message for undefined method in view
- [Luca Guidi] Ensure that layouts will include modules from `Configuration#prepare`

## v0.3.0 - 2014-12-23
### Added
- [Trung Lê] When duplicate the framework, also duplicate `Presenter`
- [Benny Klotz] Introduced `Scope#class`, `#inspect`, `LayoutScope#class` and `#inspect`
- [Alfonso Uceda Pompa & Trung Lê] Introduced `Configuration#prepare`
- [Luca Guidi] Implemented "respond to" logic for `Lotus::View::Scope` (`respond_to?` and `respond_to_missing?`)
- [Luca Guidi] Implemented "respond to" logic for `Lotus::Layout` (`respond_to?` and `respond_to_missing?`)
- [Jeremy Stephens] Allow view concrete methods that accept a block to be invoked from templates
- [Peter Suschlik] Implemented "respond to" logic for `Lotus::Presenter` (`respond_to?` and `respond_to_missing?`)
- [Luca Guidi] Official support for Ruby 2.2

### Changed
- [Alfonso Uceda Pompa] Raise an exception when a layout doesn't have an associated template

### Fixed
- [Luca Guidi] Ensure that concrete methods in layouts are available in templates
- [Luca Guidi] Ensure to associate the right layout to a view in case fo duplicated framework
- [Luca Guidi] Safe override of Ruby's top level methods in Scope. (Eg. use `select` from a view, not from `::Kernel`)

## v0.2.0 - 2014-06-23
### Added
- [Luca Guidi] Introduced `Configuration#duplicate`
- [Luca Guidi] Introduced `Configuration#layout` to define the layout that all the views will use
- [Luca Guidi] Introduced `Configuration#load_paths` to define several sources where to lookup for templates
- [Luca Guidi] Introduced `Configuration#root` to define the root path where to find templates
- [Luca Guidi] Introduced `Lotus::View::Configuration`
- [Grant Ammons] Allow view concrete methods with arity > 0 to be invoked from templates
- [Luca Guidi] Official support for Ruby 2.1

### Changed
- [Luca Guidi] `Rendering::TemplatesFinder` now look recursively for templates, starting from the root.
- [Luca Guidi] Removed `View.layout=`
- [Luca Guidi] Removed `View.root=`

### Fixed
- [Luca Guidi] Ensure outermost locals to not shadow innermost inside templates/partials

## v0.1.0 - 2014-03-23
### Added
- [Luca Guidi] Allow custom rendering policy via `Action#render` override. This bypasses the template lookup and rendering.
- [Luca Guidi] Introduced `Lotus::Presenter`
- [Luca Guidi] Introduced templates rendering from templates and layouts
- [Luca Guidi] Introduced partials rendering from templates and layouts
- [Luca Guidi] Introduced layouts support
- [Luca Guidi] Introduced `Lotus::View.load!` as entry point to load views and templates
- [Luca Guidi] Allow to setup template name via `View.template`
- [Luca Guidi] Rendering context also considers locals passed to the constructor
- [Luca Guidi] Introduced `View.format` as DSL to declare which format to handle
- [Luca Guidi] Introduced view subclasses as way to handle different formats (mime types)
- [Luca Guidi] Introduced multiple templates per each View
- [Luca Guidi] Implemented basic rendering with templates
- [Luca Guidi] Official support for Ruby 2.0
