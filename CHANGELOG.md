# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Break Versioning](https://www.taoensso.com/break-versioning).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

[Unreleased]: https://github.com/hanami/view/compare/v2.3.1...HEAD

## [2.3.1] - 2025-11-22

### Fixed

- Pass through all input arguments when exposure procs receive a keyword splat. (jaredcwhite in #269)

[2.3.1]: https://github.com/hanami/view/compare/v2.3.0...v2.3.1

## [2.3.0] - 2025-11-12

### Fixed

- Avoid warnings (from deprecated `URI::RFC3986_PARSER.extract`) in escape helper. (timriley in #267)

[2.3.0]: https://github.com/hanami/view/compare/v2.3.0.beta2...v2.3.0

## [2.3.0.beta2] - 2025-10-17

### Changed

- Drop support for Ruby 3.1.

[2.3.0.beta2]: https://github.com/hanami/view/compare/v2.3.0.beta1...v2.3.0.beta2

## [2.3.0.beta1] - 2025-10-03

[2.3.0.beta1]: https://github.com/hanami/view/compare/v2.2.1...v2.3.0.beta1

## [2.2.1] - 2025-03-17

### Fixed

- Allow multiple named scopes to be built in a single rendering (via a fix to internal scope class cache keys). (swilgosz in #253)

[2.2.1]: https://github.com/hanami/view/compare/v2.2.0...v2.2.1

## [2.2.0] - 2024-11-05

[2.2.0]: https://github.com/hanami/view/compare/v2.2.0.rc1...v2.2.0

## [2.2.0.rc1] - 2024-10-29

[2.2.0.rc1]: https://github.com/hanami/view/compare/v2.2.0.beta2...v2.2.0.rc1

## [2.2.0.beta2] - 2024-09-25

[2.2.0.beta2]: https://github.com/hanami/view/compare/v2.2.0.beta1...v2.2.0.beta2

## [2.2.0.beta1] - 2024-07-16

### Changed

- Drop support for Ruby 3.0.

[2.2.0.beta1]: https://github.com/hanami/view/compare/v2.1.0...v2.2.0.beta1

## [2.1.0] - 2024-02-27

[2.1.0]: https://github.com/hanami/view/compare/v2.1.0.rc3...v2.1.0

## [2.1.0.rc3] - 2024-02-16

### Changed

- Remove unneeded concurrent-ruby gem dependency. (Tim Riley)

[2.1.0.rc3]: https://github.com/hanami/view/compare/v2.1.0.rc2...v2.1.0.rc3

## [2.1.0.rc2] - 2023-11-08

### Changed

- Remove `LayoutNotFoundError` and raise `TemplateNotFoundError` for all kinds of missing templates, including layouts. (Tim Riley)

[2.1.0.rc2]: https://github.com/hanami/view/compare/v2.1.0.rc1...v2.1.0.rc2

## [2.1.0.rc1] - 2023-11-01

### Fixed

- Include methods from helper modules as public. Replace `module_function` with `extend self` to allow helper methods to remain directly usable on their modules, but to also let those methods remain public when the module is included in a class. This will allow an intermediary `helpers` object to be created for view parts (inside full Hanami apps) to access the standard helpers. (Tim Riley in #242)

[2.1.0.rc1]: https://github.com/hanami/view/compare/v2.1.0.beta2...v2.1.0.rc1

## [2.1.0.beta2] - 2023-10-04

### Added

- Add `Hanami::View::Rendered#match?`, `#match`, and `#include?` to make it more specs friendly. (Luca Guidi)
- Make `Hanami::View#call` to accept `layout:` keyword argument to specify the layout to use during the rendering. (Philip Arndt)

[2.1.0.beta2]: https://github.com/hanami/view/compare/v2.1.0.beta1...v2.1.0.beta2

## [2.1.0.beta1] - 2023-06-29

### Added

- Introduce new ERB engine, `Hanami::View::ERB`, now used by default for ERB templates; the erbse gem is no longer a requirement. (Tim Riley in #226)
- Introduce `Hanami::View::HTML::SafeString`, returned when calling `String#html_safe`, also introduced via a `Hanami::View::HTML::StringExtensions` module prepended onto `String`. (Tim Riley in #226)
- Auto-escape HTML based on whether it is `#html_safe?` in ERB, Haml and Slim templates. (Tim Riley in #226)
- Add `part_class` and `scope_class` settings, used by the standard `part_builder` and `scope_builder` as the default class to use when no value-specific part or scope classes can be found. These settings default to `Hanami::View::Part` and `Hanami::View::Scope` respectively. (Tim Riley in #227)
- Introduce `Hanami::View::Helpers::EscapeHelper`, `Hanami::View::Helpers::TagHelper`, `Hanami::View::Helpers::LinkToHelper`, `Hanami::View::Helpers::NumberFormattingHelper`. These helper modules may optionally be mixed into your Part and Scope classes to provide additional conveniences when authoring your views. To do this by default, create your own `Hanaim::View::Part` and `Hanami::View::Scope` subclasses that include these modules, and then configure these as the `part_class` and `scope_class` for your views. (Tim Riley in #229)

### Changed

- Use Zeitwerk for code loading; you should now require `require "hanami/view"` just once. (Tim Riley in #233)
- Change `Context` interface: custom context subclasses now have complete control over their `#initialize` (no longer need to receive `**options` or call `super`); though any mutable ivars should be duped in a custom `#initialize_copy` as required. (Tim Riley in #223)
- Change `PartBuilder` and `ScopeBuilder` interfaces to consist of static methods only. (Tim Riley in #223)
- Finalize the view class config when calling `.new` for the first time. (Tim Riley in #223)
- Consolidate all internal caches to a single `View.cache`. (Tim Riley in #223)
- [Internal] Various refactorings to improve rendering performance. (Tim Riley in #223)

[2.1.0.beta1]: https://github.com/hanami/view/compare/v2.0.0.alpha8...v2.1.0.beta1

## [2.0.0.alpha8] - 2022-05-19

### Added

- Access a hash of template locals via accessing `locals` inside any template. (Tim Riley)

### Changed

- Removed automatic integration of `Hanami::View` subclasses with their surrounding Hanami application. View base classes within Hanami apps should inherit from `Hanami::Application::View` instead. (Tim Riley)

[2.0.0.alpha8]: https://github.com/hanami/view/compare/v2.0.0.alpha7...v2.0.0.alpha8

## [2.0.0.alpha7] - 2022-03-08

### Added

- Automatically inject the app's `settings` and `assets` components (if present) into instances of `Hanami::View::ApplicationContext`. (Luca Guidi)
- Temporarily added to `Hanami::View::ApplicationContext` the `#content_for`, `#current_path` `#csrf_token` helpers, ported from the hanami-2-application-template. Some of those helpers will be moved to `hanami-helpers` gem in a later release. (Luca Guidi)

### Changed

- For views within an Hanami application, changed default location for templates from "web/templates" to "templates". (Sean Collins)
- For views within an Hanami application, the default `part_namespace` is now `"view/parts"` (previously `"views/parts"`). (Luca Guidi)

### Fixed

- Application-level configuration is now applied to `Hanami::View` subclasses, no matter how deep their inheritance chain (e.g. app base view -> slice base view -> slice view). (Luca Guidi)

[2.0.0.alpha7]: https://github.com/hanami/view/compare/v2.0.0.alpha6...v2.0.0.alpha7

## [2.0.0.alpha6] - 2022-02-10

### Added

- Official support for Ruby: MRI 3.0 and 3.1. (Luca Guidi)

### Changed

- Drop support for Ruby: MRI 2.3, 2.4, 2.5, 2.6, and 2.7. (Luca Guidi)

[2.0.0.alpha6]: https://github.com/hanami/view/compare/v2.0.0.alpha5...v2.0.0.alpha6

## [2.0.0.alpha5] - 2022-01-12

### Added

- Automatically provide access to Hanami application routes helper as `routes` in default application view context (`Hanami::View::ApplicationContext`). (Marc Busqué)

[2.0.0.alpha5]: https://github.com/hanami/view/compare/v2.0.0.alpha3...v2.0.0.alpha5

## [2.0.0.alpha3] - 2021-11-09

### Added

- Raise `LayoutNotFoundError` exception with friendlier, more specific error message when layouts cannot be found. (Pablo Vicente)

### Changed

- (Internal) Updated settings to use updated dry-configurable `setting` 0.13.0 API. (Tim Riley)

[2.0.0.alpha3]: https://github.com/hanami/view/compare/v2.0.0.alpha2...v2.0.0.alpha3

## [2.0.0.alpha2] - 2021-05-04

### Changed

- Replaced entire gem with dry-view (now renamed to hanami-view). See [dry-view's documentation](https://dry-rb.org/gems/dry-view/) for its capabilities and [the dry-view changelog](CHANGELOG.dry-view.md) for its history. (Tim Riley)

[2.0.0.alpha2]: https://github.com/hanami/view/compare/v1.3.1...v2.0.0.alpha2

## [1.3.1] - 2019-01-18

### Added

- Official support for Ruby: MRI 2.6. (Luca Guidi)
- Support `bundler` 2.0+. (Luca Guidi)

[1.3.1]: https://github.com/hanami/view/compare/v1.3.0...v1.3.1

## [1.3.0] - 2018-10-24

[1.3.0]: https://github.com/hanami/view/compare/v1.3.0.beta1...v1.3.0

## [1.3.0.beta1] - 2018-08-08

### Fixed

- Ensure to set `:disable_escape` option only for Slim and don't let Tilt to emit a warning for other template engines. (Ferdinand Niedermann)
- Ensure partial rendering to respect `format` overriding. (glaszig)

[1.3.0.beta1]: https://github.com/hanami/view/compare/v1.2.1...v1.3.0.beta1

## [1.2.1] - 2018-10-16

### Added

- Introduced new, backward compatible, signature to render a layout for testing purposes (eg. `ApplicationLayout.new({ format: :html }, "contents").render`). (Luca Guidi)

### Fixed

- Ensure layout to be rendered when using HAML 5. (Luca Guidi)
- Ensure to raise `NoMethodError` when an unknown method is invoked by a view/template. (Luca Guidi)

[1.2.1]: https://github.com/hanami/view/compare/v1.2.0...v1.2.1

## [1.2.0] - 2018-04-06

[1.2.0]: https://github.com/hanami/view/compare/v1.2.0.rc2...v1.2.0

## [1.2.0.rc2] - 2018-04-06

[1.2.0.rc2]: https://github.com/hanami/view/compare/v1.2.0.rc1...v1.2.0.rc2

## [1.2.0.rc1] - 2018-03-30

[1.2.0.rc1]: https://github.com/hanami/view/compare/v1.2.0.beta2...v1.2.0.rc1

## [1.2.0.beta2] - 2018-03-23

[1.2.0.beta2]: https://github.com/hanami/view/compare/v1.2.0.beta1...v1.2.0.beta2

## [1.2.0.beta1] - 2018-02-28

[1.2.0.beta1]: https://github.com/hanami/view/compare/v1.1.2...v1.2.0.beta1

## [1.1.2] - 2018-04-10

### Fixed

- Ensure to be able to use `exposures` even when they aren't duplicable objects. (Luca Guidi)

[1.1.2]: https://github.com/hanami/view/compare/v1.1.1...v1.1.2

## [1.1.1] - 2018-02-27

### Added

- Official support for Ruby: MRI 2.5. (Luca Guidi)

### Fixed

- Ensure that `exposures` are properly overwritten for partials when `locals:` option is used. (Alfonso Uceda)

[1.1.1]: https://github.com/hanami/view/compare/v1.1.0...v1.1.1

## [1.1.0] - 2017-10-25

[1.1.0]: https://github.com/hanami/view/compare/v1.1.0.rc1...v1.1.0

## [1.1.0.rc1] - 2017-10-16

[1.1.0.rc1]: https://github.com/hanami/view/compare/v1.1.0.beta3...v1.1.0.rc1

## [1.1.0.beta3] - 2017-10-04

[1.1.0.beta3]: https://github.com/hanami/view/compare/v1.1.0.beta2...v1.1.0.beta3

## [1.1.0.beta2] - 2017-10-03

### Added

- Added `Hanami::Layout#local` to safely access locals from layouts. (Luca Guidi)

[1.1.0.beta2]: https://github.com/hanami/view/compare/v1.1.0.beta1...v1.1.0.beta2

## [1.1.0.beta1] - 2017-08-11

### Fixed

- Raise `Hanami::View::UnknownRenderTypeError` when an argument different from `:template` or `:partial` is passed to `render`. (yjukaku)

[1.1.0.beta1]: https://github.com/hanami/view/compare/v1.0.1...v1.1.0.beta1

## [1.0.1] - 2017-08-04

### Added

- Compatibility with `haml` 5.0. (Luca Guidi)

[1.0.1]: https://github.com/hanami/view/compare/v1.0.0...v1.0.1

## [1.0.0] - 2017-04-06

[1.0.0]: https://github.com/hanami/view/compare/v1.0.0.rc1...v1.0.0

## [1.0.0.rc1] - 2017-03-31

[1.0.0.rc1]: https://github.com/hanami/view/compare/v1.0.0.beta2...v1.0.0.rc1

## [1.0.0.beta2] - 2017-03-17

### Changed

- Remove deprecated `Hanami::View::Rendering::LayoutScope#content`. (Luca Guidi)

[1.0.0.beta2]: https://github.com/hanami/view/compare/v1.0.0.beta1...v1.0.0.beta2

## [1.0.0.beta1] - 2017-02-14

### Added

- Official support for Ruby: MRI 2.4. (Luca Guidi)
- Allow `View#initialize` to splat keyword arguments. (Vladimir Dralo)

[1.0.0.beta1]: https://github.com/hanami/view/compare/v0.8.0...v1.0.0.beta1

## [0.8.0] - 2016-11-15

### Changed

- Official support for Ruby: MRI 2.3+ and JRuby 9.1.5.0+. (Luca Guidi)

### Fixed

- Ensure `Rendering::NullLocal` to work with HAML templates. (Luca Guidi)

[0.8.0]: https://github.com/hanami/view/compare/v0.7.0...v0.8.0

## [0.7.0] - 2016-07-22

### Added

- Introduced `#local` for views, layouts and templates. It allows to safely access locals without raising errors in case the referenced local is missing. (Luca Guidi)

### Changed

- Drop support for Ruby 2.0 and 2.1. Official support for JRuby 9.0.5.0+. (Luca Guidi)
- Deprecate `#content` in favor of `#local`. (Luca Guidi)

### Fixed

- Find the correct partial in case of deeply nested templates. (nessur)
- Ensure `Hanami::Presenter` to respect method visibility of wrapped object. (Marcello Rocha)
- Ensure to use new registry when loading the framework. (Luca Guidi)

[0.7.0]: https://github.com/hanami/view/compare/v0.6.1...v0.7.0

## [0.6.1] - 2016-02-05

### Changed

- Preload partial templates in order to boost performances for partials rendering (2x faster). (Steve Hook)

### Fixed

- Disable Slim autoescape to use `Hanami::View`'s feature. (Luca Guidi)

[0.6.1]: https://github.com/hanami/view/compare/v0.6.0...v0.6.1

## [0.6.0] - 2016-01-22

### Changed

- Renamed the project. (Luca Guidi)

[0.6.0]: https://github.com/hanami/view/compare/v0.5.0...v0.6.0

## [0.5.0] - 2016-01-12

### Added

- Added `Lotus::View::Configuration#default_encoding` to set the encoding for templates. (Luca Guidi)

### Changed

- Introduced `Lotus::View::Error` and let all the framework exceptions to inherit from it. (Liam Dawson)

### Fixed

- Let exceptions to be raised as they occur in rendering context. This fixes misleading backtraces for exceptions. (Luca Guidi)
- Raise a `Lotus::View::MissingTemplateError` when rendering a missing partial from a template. (Martin Rubi)
- Fix for `template.erb is not valid US-ASCII (Encoding::InvalidByteSequenceError)` when system encoding is not set. (Luca Guidi)

[0.5.0]: https://github.com/hanami/view/compare/v0.4.4...v0.5.0

## [0.4.4] - 2015-09-30

### Added

- Autoescape for layout helpers. (Luca Guidi)

[0.4.4]: https://github.com/hanami/view/compare/v0.4.3...v0.4.4

## [0.4.3] - 2015-07-10

### Fixed

- Force partial finder to be explicit when to templates have the same name. (Farrel Lifson)

[0.4.3]: https://github.com/hanami/view/compare/v0.4.2...v0.4.3

## [0.4.2] - 2015-06-23

### Fixed

- Ensure views to use methods defined by the associated layout. (Tom Kadwill)

[0.4.2]: https://github.com/hanami/view/compare/v0.4.1...v0.4.2

## [0.4.1] - 2015-05-22

### Added

- Introduced `#content` to render optional contents in a different context (eg. a view sets a page specific javascript in the application template footer). (Luca Guidi)

[0.4.1]: https://github.com/hanami/view/compare/v0.4.0...v0.4.1

## [0.4.0] - 2015-03-23

### Changed

- Autoescape concrete and virtual methods from presenters. (Luca Guidi)
- Autoescape concrete and virtual methods from views. (Luca Guidi)

### Fixed

- Improve error message for undefined method in view. (Tom Kadwill)
- Ensure that layouts will include modules from `Configuration#prepare`. (Luca Guidi)

[0.4.0]: https://github.com/hanami/view/compare/v0.3.0...v0.4.0

## [0.3.0] - 2014-12-23

### Added

- When duplicate the framework, also duplicate `Presenter`. (Trung Lê)
- Introduced `Scope#class`, `#inspect`, `LayoutScope#class` and `#inspect`. (Benny Klotz)
- Introduced `Configuration#prepare`. (Alfonso Uceda Pompa & Trung Lê)
- Implemented "respond to" logic for `Lotus::View::Scope` (`respond_to?` and `respond_to_missing?`). (Luca Guidi)
- Implemented "respond to" logic for `Lotus::Layout` (`respond_to?` and `respond_to_missing?`). (Luca Guidi)
- Allow view concrete methods that accept a block to be invoked from templates. (Jeremy Stephens)
- Implemented "respond to" logic for `Lotus::Presenter` (`respond_to?` and `respond_to_missing?`). (Peter Suschlik)
- Official support for Ruby 2.2. (Luca Guidi)

### Changed

- Raise an exception when a layout doesn't have an associated template. (Alfonso Uceda Pompa)

### Fixed

- Ensure that concrete methods in layouts are available in templates. (Luca Guidi)
- Ensure to associate the right layout to a view in case fo duplicated framework. (Luca Guidi)
- Safe override of Ruby's top level methods in Scope. (Eg. use `select` from a view, not from `::Kernel`). (Luca Guidi)

[0.3.0]: https://github.com/hanami/view/compare/v0.2.0...v0.3.0

## [0.2.0] - 2014-06-23

### Added

- Introduced `Configuration#duplicate`. (Luca Guidi)
- Introduced `Configuration#layout` to define the layout that all the views will use. (Luca Guidi)
- Introduced `Configuration#load_paths` to define several sources where to lookup for templates. (Luca Guidi)
- Introduced `Configuration#root` to define the root path where to find templates. (Luca Guidi)
- Introduced `Lotus::View::Configuration`. (Luca Guidi)
- Allow view concrete methods with arity > 0 to be invoked from templates. (Grant Ammons)
- Official support for Ruby 2.1. (Luca Guidi)

### Changed

- `Rendering::TemplatesFinder` now look recursively for templates, starting from the root. (Luca Guidi)
- Removed `View.layout=`. (Luca Guidi)
- Removed `View.root=`. (Luca Guidi)

### Fixed

- Ensure outermost locals to not shadow innermost inside templates/partials. (Luca Guidi)

[0.2.0]: https://github.com/hanami/view/compare/v0.1.0...v0.2.0

## [0.1.0] - 2014-03-23

### Added

- Allow custom rendering policy via `Action#render` override. This bypasses the template lookup and rendering. (Luca Guidi)
- Introduced `Lotus::Presenter`. (Luca Guidi)
- Introduced templates rendering from templates and layouts. (Luca Guidi)
- Introduced partials rendering from templates and layouts. (Luca Guidi)
- Introduced layouts support. (Luca Guidi)
- Introduced `Lotus::View.load!` as entry point to load views and templates. (Luca Guidi)
- Allow to setup template name via `View.template`. (Luca Guidi)
- Rendering context also considers locals passed to the constructor. (Luca Guidi)
- Introduced `View.format` as DSL to declare which format to handle. (Luca Guidi)
- Introduced view subclasses as way to handle different formats (mime types). (Luca Guidi)
- Introduced multiple templates per each View. (Luca Guidi)
- Implemented basic rendering with templates. (Luca Guidi)
- Official support for Ruby 2.0. (Luca Guidi)

[0.1.0]: https://github.com/hanami/view/releases/tag/v0.1.0
