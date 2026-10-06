# frozen_string_literal: true

module Hanami
  class View
    # The output of a view rendering.
    #
    # @api public
    # @since 2.1.0
    class Rendered
      # Returns the rendered view output.
      #
      # @return [String]
      #
      # @see to_s
      # @see to_str
      #
      # @api public
      # @since 2.1.0
      attr_reader :output

      # @api private
      # @since 2.1.0
      def initialize(output:, locals:)
        @output = output
        @locals = locals
      end

      # Returns the locals used to render the view output.
      #
      # These are the same lazy locals the template received. Reading a local resolves its exposure
      # if rendering did not already. Call `#to_h` to get a Hash of every local, which resolves
      # every exposure.
      #
      # @return [Locals]
      #
      # @api public
      # @since 2.1.0
      attr_reader :locals

      # Returns the local corresponding to the key.
      #
      # Resolves the matching exposure (and its dependencies) if it was not already resolved
      # during rendering.
      #
      # @param name [Symbol] local key
      #
      # @return [Hanami::View::Part]
      #
      # @api public
      # @since 2.1.0
      def [](name)
        @locals[name]
      end

      # Returns the rendered view output.
      #
      # @return [String]
      #
      # @api public
      # @since 2.1.0
      def to_s
        output
      end

      # @api public
      # @since 2.1.0
      alias_method :to_str, :to_s

      # Returns true if the given object has the same rendered output.
      #
      # Compares against another Rendered, or any String-like object (one that responds to
      # `#to_str`). Since Rendered responds to `#to_str`, comparing from a String works too.
      #
      # Does not compare locals, so does not resolve any exposures.
      #
      # @example
      #   rendered == "<p>Hello</p>" # => true
      #   "<p>Hello</p>" == rendered # => true
      #
      # @param other [Object]
      #
      # @return [Boolean]
      #
      # @api public
      # @since 3.1.0
      def ==(other)
        if other.is_a?(Rendered)
          output == other.output
        elsif other.respond_to?(:to_str)
          output == other.to_str
        else
          false
        end
      end

      # Returns true if the given object is a Rendered with the same rendered output.
      #
      # Unlike {#==}, this is false for Strings.
      #
      # @param other [Object]
      #
      # @return [Boolean]
      #
      # @api public
      # @since 3.1.0
      def eql?(other)
        other.is_a?(Rendered) && output.eql?(other.output)
      end

      # @api public
      # @since 3.1.0
      def hash
        [self.class, output].hash
      end

      # Returns true if the given input matches the rendered view output.
      #
      # @param matcher [String, Regexp] matcher
      #
      # @return [TrueClass,FalseClass]
      #
      # @api public
      # @since 2.1.0
      def match?(matcher)
        output.match?(matcher)
      end
      alias_method :match, :match?

      # Returns true if given string is included in the rendered view output.
      #
      # @param string [String] string
      #
      # @return [TrueClass,FalseClass]
      #
      # @api public
      # @since 2.1.0
      def include?(string)
        output.include?(string)
      end
    end
  end
end
