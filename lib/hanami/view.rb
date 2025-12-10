# frozen_string_literal: true

require "dry/configurable"
require "dry/core/equalizer"
require "dry/inflector"
require "zeitwerk"

require_relative "view/errors"
require_relative "view/html"

module Hanami
  # A standalone, template-based view rendering system that offers everything you need to write
  # well-factored view code.
  #
  # This represents a single view, holding the configuration and exposures necessary for rendering
  # its template.
  #
  # @abstract Subclass this and provide your own configuration and exposures to define your own view
  #   (along with a custom `#initialize` if you wish to inject dependencies into your subclass)
  #
  # @api public
  # @since 2.1.0
  class View
    # @api private
    # @since 2.1.0
    def self.gem_loader
      @gem_loader ||= Zeitwerk::Loader.new.tap do |loader|
        root = File.expand_path("..", __dir__)
        loader.tag = "hanami-view"
        loader.push_dir(root)
        loader.ignore(
          "#{root}/hanami-view.rb",
          "#{root}/hanami/view/version.rb",
          "#{root}/hanami/view/errors.rb",
          "#{root}/hanami/view/tilt/*.rb"
        )
        loader.inflector = Zeitwerk::GemInflector.new("#{root}/hanami-view.rb")
        loader.inflector.inflect(
          "erb" => "ERB",
          "html" => "HTML",
          "html_safe_string_buffer" => "HTMLSafeStringBuffer",
        )
      end
    end

    gem_loader.setup

    # @api private
    # @since 2.1.0
    DEFAULT_RENDERER_OPTIONS = {default_encoding: "utf-8"}.freeze

    include Dry::Equalizer(:config, :exposures)

    extend Dry::Configurable

    # @!group Configuration

    # @overload config.paths=(paths)
    #   Set an array of directories that will be searched for all templates
    #   (templates, partials, and layouts).
    #
    #   These will be converted into Path objects and used for template lookup
    #   when rendering.
    #
    #   This is a **required setting**.
    #
    #   @param paths [String, Path, Array<String, Path>] the paths
    #
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :paths, constructor: -> paths {
      Array(paths).map { |path| Path[path] }
    }

    # @overload config.template=(name)
    #   Set the name of the template for rendering this view. Template name
    #   should be relative to the configured `paths`.
    #
    #   This is a **required setting**.
    #
    #   @param name [String] template name
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :template

    # @overload config.template_inference_base=(base_path)
    #   Set the base path to strip away when when inferring a view's template
    #   names from its class name.
    #
    #   **This setting only applies for views within an Hanami application.**
    #
    #   For example, given a view `Main::Views::Articles::Index`, in the `Main`
    #   slice, and a template_inference_base of "views", the inferred template
    #   name will be "articles/index".
    #
    #   @param base_path [String, nil] base templates path
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :template_inference_base

    # @overload config.layout=(name)
    #   Set the name of the layout to render templates within. Layouts will be
    #   looked up within the configured `layouts_dir`, within the configured
    #   `paths`.
    #
    #   A false or nil value will use no layout. Defaults to `nil`.
    #
    #   @param name [String, FalseClass, nil] layout name, or false to indicate no layout
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :layout, default: false

    # @overload config.layouts_dir=(dir)
    #   Set the name of the directory (within the configured `paths`) holding
    #   the layouts. Defaults to `"layouts"`
    #
    #   @param dir [String] directory name
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :layouts_dir, default: "layouts"

    # @overload config.scope=(scope_class)
    #   Set the scope class to use when rendering the view's template.
    #
    #   Configuring a custom scope class allows you to provide extra behaviour
    #   (alongside exposures) to the template.
    #
    #   @see https://dry-rb.org/gems/dry-view/scopes/
    #
    #   @param scope_class [Class] scope class (inheriting from `Hanami::View::Scope`)
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :scope

    # @overload config.default_context=(context)
    #   Set the default context object to use when rendering. This will be used
    #   unless another context object is applied at render-time to `View#call`
    #
    #   Defaults to a frozen instance of `Hanami::View::Context`.
    #
    #   @see View#call
    #
    #   @param context [Hanami::View::Context] context object
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :default_context, default: Context.new.freeze

    # @overload config.default_format=(format)
    #   Set the default format to use when rendering.
    #
    #   Defaults to `:html`.
    #
    #   @param format [Symbol]
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :default_format, default: :html

    # @overload config.part_class=(part_class)
    #   Set a custom default part class.
    #
    #   @param part_class [Class]
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :part_class, default: Part

    # @overload config.scope_namespace=(namespace)
    #   Set a namespace that will be searched when building scope classes.
    #
    #   @param namespace [Module, Class]
    #
    #   @see Scope
    #
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :part_namespace

    # @overload config.part_builder=(part_builder)
    #   Set a custom part builder class
    #
    #   @param part_builder [Class]
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :part_builder, default: PartBuilder

    # @overload config.scope_class=(scope_class)
    #   Set a custom default scope class.
    #
    #   @param scope_class [Class]
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :scope_class, default: Scope

    # @overload config.scope_namespace=(namespace)
    #   Set a namespace that will be searched when building scope classes.
    #
    #   @param namespace [Module, Class]
    #
    #   @see Scope
    #
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :scope_namespace

    # @overload config.scope_builder=(scope_builder)
    #   Set a custom scope builder class
    #
    #   @see https://dry-rb.org/gems/dry-view/scopes/
    #
    #   @param scope_builder [Class]
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :scope_builder, default: ScopeBuilder

    # @overload config.inflector=(inflector)
    #   Set an inflector to provide to the part_builder and scope_builder.
    #
    #   Defaults to `Dry::Inflector.new`.
    #
    #   @param inflector
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :inflector, default: Dry::Inflector.new

    # @overload config.renderer_options=(options)
    #   A hash of options to pass to the template engine. Template engines are
    #   provided by Tilt; see Tilt's documentation for what options your
    #   template engine may support.
    #
    #   Defaults to `{default_encoding: "utf-8"}`. Any options passed will be
    #   merged onto the defaults.
    #
    #   @see https://github.com/rtomayko/tilt
    #
    #   @param options [Hash] renderer options
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :renderer_options, default: DEFAULT_RENDERER_OPTIONS, constructor: -> options {
      DEFAULT_RENDERER_OPTIONS.merge(options.to_h).freeze
    }

    # @overload config.renderer_engine_mapping=(mapping)
    #   A hash specifying the (Tilt-compatible) template engine class to use
    #   for a given format. Template engine detection is automatic based on
    #   format; use this setting only if you want to force a non-preferred
    #   engine.
    #
    #   @example
    #     config.renderer_engine_mapping = {erb: Tilt::ErubiTemplate}
    #
    #   @see https://github.com/rtomayko/tilt
    #
    #   @param mapping [Hash<Symbol, Class>] engine mapping
    #   @api public
    #   @since 2.1.0
    # @!scope class
    setting :renderer_engine_mapping, default: {}

    # @!endgroup

    # @api private
    # @since 2.1.0
    def self.inherited(klass)
      super

      exposures.each do |name, exposure|
        klass.exposures.import(name, exposure)
      end
    end

    # @!group Exposures

    # @!macro [new] exposure_options
    #   @param options [Hash] the exposure's options
    #   @option options [Boolean] :layout expose this value to the layout (defaults to false)
    #   @option options [Boolean] :decorate decorate this value in a matching Part (defaults to
    #     true)
    #   @option options [Symbol, Class] :as an alternative name or class to use when finding a
    #     matching Part

    # @overload expose(name, **options, &block)
    #   Define a value to be passed to the template. The return value of the
    #   block will be decorated by a matching Part and passed to the template.
    #
    #   The block will be evaluated with the view instance as its `self`. The
    #   block's parameters will determine what it is given:
    #
    #   - To receive other exposure values, provide positional parameters
    #     matching the exposure names. These exposures will already by decorated
    #     by their Parts.
    #   - To receive the view's input arguments (whatever is passed to
    #     `View#call`), provide matching keyword parameters. You can provide
    #     default values for these parameters to make the corresponding input
    #     keys optional
    #   - To receive the Context object, provide a `context:` keyword parameter
    #   - To receive the view's input arguments in their entirety, provide a
    #     keywords splat parameter (i.e. `**input`)
    #
    #   @example Accessing input arguments
    #     expose :article do |slug:|
    #       article_repo.find_by_slug(slug)
    #     end
    #
    #   @example Accessing other exposures
    #     expose :articles do
    #       article_repo.listing
    #     end
    #
    #     expose :featured_articles do |articles|
    #       articles.select(&:featured?)
    #     end
    #
    #   @param name [Symbol] name for the exposure
    #   @macro exposure_options
    #
    # @overload expose(name, **options)
    #   Define a value to be passed to the template, provided by an instance
    #   method matching the name. The method's return value will be decorated by
    #   a matching Part and passed to the template.
    #
    #   The method's parameters will determine what it is given:
    #
    #   - To receive other exposure values, provide positional parameters
    #     matching the exposure names. These exposures will already by decorated
    #     by their Parts.
    #   - To receive the view's input arguments (whatever is passed to
    #     `View#call`), provide matching keyword parameters. You can provide
    #     default values for these parameters to make the corresponding input
    #     keys optional
    #   - To receive the Context object, provide a `context:` keyword parameter
    #   - To receive the view's input arguments in their entirety, provide a
    #     keywords splat parameter (i.e. `**input`)
    #
    #   @example Accessing input arguments
    #     expose :article
    #
    #     def article(slug:)
    #       article_repo.find_by_slug(slug)
    #     end
    #
    #   @example Accessing other exposures
    #     expose :articles
    #     expose :featured_articles
    #
    #     def articles
    #       article_repo.listing
    #     end
    #
    #     def featured_articles
    #       articles.select(&:featured?)
    #     end
    #
    #   @param name [Symbol] name for the exposure
    #   @macro exposure_options
    #
    # @overload expose(name, **options)
    #   Define a single value to pass through from the input data (when there is
    #   no instance method matching the `name`). This value will be decorated by
    #   a matching Part and passed to the template.
    #
    #   @param name [Symbol] name for the exposure
    #   @macro exposure_options
    #   @option options [Boolean] :default a default value to provide if there is no matching
    #     input data
    #
    # @overload expose(*names, **options)
    #   Define multiple values to pass through from the input data (when there
    #   is no instance methods matching their names). These values will be
    #   decorated by matching Parts and passed through to the template.
    #
    #   The provided options will be applied to all the exposures.
    #
    #   @param names [Symbol] names for the exposures
    #   @macro exposure_options
    #   @option options [Boolean] :default a default value to provide if there is no matching
    #     input data
    #
    # @see https://dry-rb.org/gems/dry-view/exposures/
    #
    # @api public
    # @since 2.1.0
    def self.expose(*names, **options, &block)
      if names.length == 1
        exposures.add(names.first, block, **options)
      else
        names.each do |name|
          exposures.add(name, **options)
        end
      end
    end

    # @see expose
    #
    # @api public
    # @since 2.1.0
    def self.private_expose(*names, **options, &block)
      expose(*names, **options, private: true, &block)
    end

    # Returns the defined exposures. These are unbound, since bound exposures
    # are only created when initializing a View instance.
    #
    # @return [Exposures]
    # @api private
    # @since 2.1.0
    def self.exposures
      @exposures ||= Exposures.new
    end

    # @!endgroup

    # @!group Scope

    # Creates and assigns a scope for the current view.
    #
    # The newly created scope is useful to add custom logic that is specific
    # to the view.
    #
    # The scope has access to locals, exposures, and inherited scope (if any)
    #
    # If the view already has an explicit scope the newly created scope will
    # inherit from the explicit scope.
    #
    # There are two cases when this may happen:
    #   1. The scope was explicitly assigned (e.g. `config.scope = MyScope`)
    #   2. The scope has been inherited by the view superclass
    #
    # If the view doesn't have an already existing scope, the newly scope
    # will inherit from `Hanami::View::Scope` by default.
    #
    # However, you can specify any base class for it. This is not
    # recommended, unless you know what you're doing.
    #
    # @param scope [Hanami::View::Scope] the current scope (if any), or the
    #   default base class will be `Hanami::View::Scope`
    # @param block [Proc] the scope logic definition
    #
    # @api public
    #
    # @example Basic usage
    #   class MyView < Hanami::View
    #     config.scope = MyScope
    #
    #     scope do
    #       def greeting
    #         _locals[:message].upcase + "!"
    #       end
    #
    #       def copyright(time)
    #         "Copy #{time.year}"
    #       end
    #     end
    #   end
    #
    #   # my_view.html.erb
    #   # <%= greeting %>
    #   # <%= copyright(Time.now.utc) %>
    #
    #   MyView.new.(message: "Hello") # => "HELLO!"
    #
    # @example Inherited scope
    #   class MyScope < Hanami::View::Scope
    #     private
    #
    #     def shout(string)
    #       string.upcase + "!"
    #     end
    #   end
    #
    #   class MyView < Hanami::View
    #     config.scope = MyScope
    #
    #     scope do
    #       def greeting
    #         shout(_locals[:message])
    #       end
    #
    #       def copyright(time)
    #         "Copy #{time.year}"
    #       end
    #     end
    #   end
    #
    #   # my_view.html.erb
    #   # <%= greeting %>
    #   # <%= copyright(Time.now.utc) %>
    #
    #   MyView.new.call(message: "Hello") # => "HELLO!"
    #
    # @api public
    # @since 2.1.0
    def self.scope(scope_class = nil, &block)
      scope_class ||= config.scope || config.scope_class

      config.scope = Class.new(scope_class, &block)
    end

    # @!endgroup

    # @api private
    # @since 2.1.0
    def self.layout_path(layout)
      File.join(*[config.layouts_dir, layout].compact)
    end

    # @api private
    # @since 2.1.0
    def self.cache
      Cache
    end

    # Returns an instance of the view. This binds the defined exposures to the view instance.
    #
    # Subclasses can define their own `#initialize` to accept injected dependencies, but must call
    # `super()` to ensure the standard view initialization can proceed.
    #
    # @api public
    # @since 2.1.0
    def initialize
      self.class.config.finalize!
      ensure_config

      @exposures = self.class.exposures.bind(self)
    end

    # Returns the view's configuration.
    #
    # @api public
    # @since 2.1.0
    def config
      self.class.config
    end

    # Returns the view's bound exposures.
    #
    # @return [Exposures]
    #
    # @api private
    # @since 2.1.0
    def exposures
      @exposures
    end

    # Renders the view.
    #
    # @param format [Symbol] template format to use
    # @param context [Context] context object to use
    # @param layout [String, FalseClass, nil] layout name, or false to indicate no layout
    # @param input input data for preparing exposure values
    #
    # @return [Rendered] rendered view object
    #
    # @api public
    # @since 2.1.0
    def call(format: config.default_format, context: config.default_context, layout: config.layout, **input)
      rendering = self.rendering(format: format, context: context)

      locals = locals(rendering, input)
      output = rendering.template(config.template, rendering.scope(config.scope, locals))

      if layout
        output = rendering.template(
          self.class.layout_path(layout),
          rendering.scope(config.scope, layout_locals(locals))
        ) { output }
      end

      Rendered.new(output: output, locals: locals)
    end

    # @api private
    # @since 2.1.0
    def rendering(format: config.default_format, context: config.default_context)
      Rendering.new(config: config, format: format, context: context)
    end

    private

    def ensure_config
      raise UndefinedConfigError, :paths unless Array(config.paths).any?
      raise UndefinedConfigError, :template unless config.template
    end

    def locals(rendering, input)
      exposures.(context: rendering.context, **input) do |value, exposure|
        if exposure.decorate? && value
          rendering.part(exposure.name, value, as: exposure.options[:as])
        else
          value
        end
      end
    end

    def layout_locals(locals)
      locals.each_with_object({}) do |(key, value), layout_locals|
        layout_locals[key] = value if exposures[key].for_layout?
      end
    end
  end
end
