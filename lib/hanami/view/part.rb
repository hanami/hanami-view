# frozen_string_literal: true

require "dry/core/equalizer"

module Hanami
  class View
    # Decorates an exposure value and provides a place to encapsulate
    # view-specific behavior alongside your application's domain objects.
    #
    # @abstract Subclass this and provide your own methods adding view-specific
    #   behavior. You should not override `#initialize`.
    #
    # @see https://dry-rb.org/gems/dry-view/parts/
    #
    # @api public
    # @since 2.1.0
    class Part
      # @api private
      # @since 2.1.0
      CONVENIENCE_METHODS = %i[
        format
        context
        render
        scope
        value
      ].freeze

      include Dry::Equalizer(:_name, :_value, :_rendering)
      include DecoratedAttributes

      # The part's name. This comes from the exposure supplying the value.
      #
      # @return [Symbol] name
      #
      # @api public
      # @since 2.1.0
      attr_reader :_name

      # The decorated value. This is the value returned from the exposure.
      #
      # @overload _value
      #   Returns the value.
      # @overload value
      #   A convenience alias for `_value`. Is available unless the value itself
      #   responds to `#value`.
      #
      # @return [Object] value
      #
      # @api public
      # @since 2.1.0
      attr_reader :_value

      # The current rendering
      #
      # @return [Rendering]
      #
      # @api private
      # @since 2.1.0
      attr_reader :_rendering

      # Determines a part name (when initialized without one). Intended for internal use only while
      # unit testing Parts.
      #
      # @return [String]
      #
      # @api private
      # @since 2.1.0
      def self.part_name(inflector)
        name ? inflector.underscore(inflector.demodulize(name)) : "part"
      end

      # Returns a new Part instance
      #
      # @param name [Symbol] part name
      # @param value [Object] the value to decorate
      # @param rendering [Rendering] the current rendering
      #
      # @api public
      # @since 2.1.0
      def initialize(
        value:,
        rendering: RenderingMissing.new,
        name: self.class.part_name(rendering.inflector)
      )
        @_name = name
        @_value = value
        @_rendering = rendering
      end

      # Returns the template format for the current rendering.
      #
      # @overload _format
      #   Returns the format.
      # @overload format
      #   A convenience alias for `#_format.` Is available unless the value
      #   itself responds to `#format`.
      #
      # @return [Symbol] format
      #
      # @api public
      # @since 2.1.0
      def _format
        _rendering.format
      end

      # Returns the context object for the current rendering.
      #
      # @overload _context
      #   Returns the context.
      # @overload context
      #   A convenience alias for `#_context`. Is available unless the value
      #   itself responds to `#context`.
      #
      # @return [Context] context
      #
      # @api public
      # @since 2.1.0
      def _context
        _rendering.context
      end

      # Renders a new partial with the part included in its locals.
      #
      # @overload _render(partial_name, as: _name, **locals, &block)
      #   Renders the partial.
      # @overload render(partial_name, as: _name, **locals, &block)
      #   A convenience alias for `#_render`. Is available unless the value
      #   itself responds to `#render`.
      #
      # @param partial_name [Symbol, String] partial name
      # @param as [Symbol] the name for the Part to assume in the partial's locals. Defaults to
      #   the Part's `_name`.
      # @param locals [Hash<Symbol, Object>] other locals to provide the partial
      #
      # @return [String] rendered partial
      #
      # @api public
      # @since 2.1.0
      def _render(partial_name, as: _name, **locals, &block)
        _rendering.partial(partial_name, _rendering.scope({as => self}.merge(locals)), &block)
      end

      # Builds a new scope with the part included in its locals.
      #
      # @overload _scope(scope_name = nil, **locals)
      #   Builds the scope.
      # @overload scope(scope_name = nil, **locals)
      #   A convenience alias for `#_scope`. Is available unless the value
      #   itself responds to `#scope`.
      #
      # @param scope_name [Symbol, nil] scope name, used by the scope builder to determine the
      #   scope class
      # @param locals [Hash<Symbol, Object>] other locals to provide the partial
      #
      # @return [Hanami::View::Scope] scope
      #
      # @api public
      # @since 2.1.0
      def _scope(scope_name = nil, **locals)
        _rendering.scope(scope_name, {_name => self}.merge(locals))
      end

      # Returns a string representation of the value.
      #
      # @return [String]
      #
      # @api public
      # @since 2.1.0
      def to_s
        _value.to_s
      end

      # Builds a new a part with the given parameters.
      #
      # This is helpful for manually constructing a new part object that maintains the current
      # rendering.
      #
      # However, using `.decorate` is preferred for declaring attributes that should also be
      # decorated as parts.
      #
      # @see DecoratedAttributes::ClassInterface#decorate
      #
      # @param klass [Class] part class to use (defaults to the part's class)
      # @param name [Symbol] part name (defaults to the part's name)
      # @param value [Object] value to decorate (defaults to the part's value)
      # @param options[Hash<Symbol, Object>] other options to provide when initializing the new part
      #
      # @api public
      # @since 2.1.0
      def new(klass = self.class, name: _name, value: _value, **options)
        klass.new(
          name: name,
          value: value,
          rendering: _rendering,
          **options
        )
      end

      # Returns a string representation of the part.
      #
      # @return [String]
      #
      # @api public
      # @since 2.1.0
      def inspect
        %(#<#{self.class.name} name=#{_name.inspect} value=#{_value.inspect}>)
      end

      private

      # Handles missing methods. If the `_value` responds to the method, then
      # the method will be sent to the value.
      def method_missing(name, *args, &block)
        if _value.respond_to?(name)
          _value.public_send(name, *args, &block)
        elsif CONVENIENCE_METHODS.include?(name)
          __send__(:"_#{name}", *args, &block)
        else
          super
        end
      end
      ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

      def respond_to_missing?(name, include_private = false)
        CONVENIENCE_METHODS.include?(name) || _value.respond_to?(name, include_private) || super
      end
    end
  end
end
