# frozen_string_literal: true

require "dry/core/equalizer"

module Hanami
  class View
    # The output of a view rendering.
    #
    # @api public
    # @since 2.1.0
    class Rendered
      include Dry::Equalizer(:output, :locals)

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

      # Returns the hash of locals used to render the view output.
      #
      # Resolves every exposure not already resolved during rendering.
      #
      # @return [Hash[<Symbol, Hanami::View::Part>] locals hash
      #
      # @api public
      # @since 2.1.0
      def locals
        @locals.to_h
      end

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
