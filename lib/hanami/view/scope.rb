# frozen_string_literal: true

require "dry/core/equalizer"
require "dry/core/constants"

module Hanami
  class View
    # Evaluation context for templates (including layouts and partials) and
    # provides a place to encapsulate view-specific behaviour alongside a
    # template and its locals.
    #
    # @abstract Subclass this and provide your own methods adding view-specific
    #   behavior. You should not override `#initialize`
    #
    # @see https://dry-rb.org/gems/dry-view/templates/
    # @see https://dry-rb.org/gems/dry-view/scopes/
    #
    # @api public
    # @since 2.1.0
    class Scope
      # @api private
      CONVENIENCE_METHODS = %i[format context locals template_name].freeze

      include Dry::Equalizer(:_name, :_locals, :_rendering)

      class << self
        # Declares the locals the scope takes.
        #
        # A scope built with {#scope} (from a template or a part) is then checked against the
        # declaration: a missing or unknown local raises an `ArgumentError`, and defaults are
        # filled in for locals not given. The scope's methods and the partials it renders see the
        # locals with their defaults.
        #
        # This declares what the scope takes, not what any one partial takes, since a scope can
        # render more than one partial.
        #
        # Subclasses inherit the declaration, and may replace it with their own.
        #
        # @example
        #   class Greeting < Hanami::View::Scope
        #     locals :name, greeting: "Hello"
        #
        #     def message = "#{greeting}, #{name}!"
        #   end
        #
        # @param required [Array<Symbol>] locals the scope must be given
        # @param defaults [Hash{Symbol => Object}] locals the scope may be given, with their
        #   defaults
        #
        # @return [void]
        #
        # @api public
        # @since 3.1.0
        def locals(*required, **defaults)
          @_locals_declaration = ScopeLocals.new(scope_class: self, required:, defaults:)
        end

        # Returns the scope's declared locals, or nil if it declares none.
        #
        # @return [ScopeLocals, nil]
        #
        # @api private
        # @since 3.1.0
        def _locals_declaration
          return @_locals_declaration if instance_variable_defined?(:@_locals_declaration)

          superclass._locals_declaration if superclass.respond_to?(:_locals_declaration)
        end

        # Returns the locals checked against the scope's declaration, with defaults filled in, or
        # the locals unchanged if it declares none.
        #
        # @param locals [Hash{Symbol => Object}]
        #
        # @return [Hash{Symbol => Object}]
        #
        # @api private
        # @since 3.1.0
        def _declared_locals(locals)
          declaration = _locals_declaration
          declaration ? declaration.(locals) : locals
        end
      end

      # Returns the scope's name.
      #
      # @return [Symbol]
      #
      # @api public
      # @since 2.1.0
      attr_reader :_name

      # Returns the scope's locals
      #
      # @overload _locals
      #   Returns the locals.
      #   @return [Hash{Symbol => Object}]
      # @overload locals
      #   A convenience alias for `#_locals.` Is available unless there is a local named `locals`
      #   @return [Hash{Symbol => Object}]
      #
      # @api public
      # @since 2.1.0
      attr_reader :_locals

      # Returns the current rendering.
      #
      # @return [Rendering]
      #
      # @api private
      # @since 2.1.0
      attr_reader :_rendering

      # Returns a new Scope instance.
      #
      # @param name [Symbol, nil] scope name
      # @param locals [Hash<Symbol, Object>] template locals
      # @param rendering [Rendering] the current rendering
      #
      # @return [Scope]
      #
      # @api public
      # @since 2.1.0
      def initialize(
        name: nil,
        locals: Dry::Core::Constants::EMPTY_HASH,
        rendering: RenderingMissing.new
      )
        @_name = name
        @_locals = locals
        @_rendering = rendering
      end

      # @overload render(partial_name, **locals, &block)
      #   Renders a partial using the scope.
      #
      #   @param partial_name [Symbol, String] partial name
      #   @param locals [Hash{Symbol => Object}] partial locals
      #   @yieldreturn [String] string content to include where the partial calls `yield`
      #   @return [String] the rendered partial output
      #
      # @overload render(**locals, &block)
      #   Renders a partial (named after the scope's own name) using the scope.
      #
      #   @param locals [Hash{Symbol => Object}] partial locals
      #   @yieldreturn [String] string content to include where the partial calls `yield`
      #   @return [String] the rendered partial output
      #
      # @api public
      # @since 2.1.0
      def render(partial_name = nil, **locals, &block)
        partial_name ||= _name

        unless partial_name
          raise ArgumentError, "+partial_name+ must be provided for unnamed scopes"
        end

        if partial_name.is_a?(Class)
          partial_name = _inflector.underscore(_inflector.demodulize(partial_name.to_s))
        end

        _rendering.partial(partial_name, _render_scope(**locals), &block)
      end

      # Builds a new scope using a scope class matching the provided name.
      #
      # @param name [Symbol, Class] scope name (or class)
      # @param locals [Hash<Symbol, Object>] scope locals
      #
      # @return [Scope]
      #
      # @raise [ArgumentError] if the scope class declares its locals (see {.locals}) and one is
      #   missing or unknown
      #
      # @api public
      # @since 2.1.0
      def scope(name = nil, **locals)
        _rendering.scope(name, locals)._with_declared_locals
      end

      # Returns the scope with its locals checked against its class's declaration and defaults
      # filled in, or the scope itself if its class declares none.
      #
      # @return [Scope]
      #
      # @raise [ArgumentError] if a declared local is missing, or a local is not declared
      #
      # @api private
      # @since 3.1.0
      def _with_declared_locals
        declared = self.class._declared_locals(_locals)
        return self if declared.equal?(_locals)

        self.class.new(name: _name, locals: declared, rendering: _rendering)
      end

      # Returns the template format for the current render environment.
      #
      # @overload _format
      #   Returns the format.
      #   @return [Symbol] format
      # @overload format
      #   A convenience alias for `#_format.` Is available unless there is a local named `format`.
      #   @return [Symbol] format
      #
      # @api public
      # @since 2.1.0
      def _format
        _rendering.format
      end

      # Returns the context object for the current render environment.
      #
      # @overload _context
      #   Returns the context.
      #   @return [Context] context
      # @overload context
      #   A convenience alias for `#_context`. Is available unless there is a local named `context`.
      #   @return [Context] context
      #
      # @api public
      # @since 2.1.0
      def _context
        _rendering.context
      end

      # Returns the name of the template or partial currently being rendered.
      #
      # @overload _template_name
      #   Returns the current template name.
      #   @return [String, nil]
      # @overload template_name
      #   A convenience alias for `#_template_name`. Is available unless there is a local named
      #   `template_name`.
      #   @return [String, nil]
      #
      # @api public
      # @since 3.0.0
      def _template_name
        _rendering.current_template_name
      end

      private

      # Handles missing methods, according to the following rules:
      #
      # 1. If there is a local with a name matching the method, it returns the local.
      # 2. If the `context` responds to the method, then it will be sent the method and all its
      #    arguments.
      def method_missing(name, *args, &block)
        if _locals.key?(name)
          _locals[name]
        elsif _context.respond_to?(name)
          _context.public_send(name, *args, &block)
        elsif CONVENIENCE_METHODS.include?(name)
          __send__(:"_#{name}", *args, &block)
        else
          super
        end
      end
      ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

      def respond_to_missing?(name, include_private = false)
        _locals.key?(name) ||
          _rendering.context.respond_to?(name) ||
          CONVENIENCE_METHODS.include?(name) ||
          super
      end

      def _render_scope(**locals)
        if locals.none?
          self
        else
          self.class.new(
            # FIXME: what about `name`?
            locals: locals,
            rendering: _rendering
          )
        end
      end

      def _inflector
        _rendering.inflector
      end
    end
  end
end
