# frozen_string_literal: true

module Hanami
  class View
    # Base error for views.
    #
    # @since 2.1.0
    # @api public
    class Error < StandardError
    end

    # Error raised when critical settings are not configured.
    #
    # @api public
    # @since 2.1.0
    class UndefinedConfigError < StandardError
      def initialize(key)
        super("no +#{key}+ configured")
      end
    end

    # Error raised when template could not be found within a view's configured paths.
    #
    # @api public
    # @since 2.1.0
    class TemplateNotFoundError < StandardError
      def initialize(template_name, format, lookup_paths)
        msg = [
          "Template `#{template_name}' for format `#{format}' could not be found in paths:",
          lookup_paths.map { |path| " - #{path}" }
        ].join("\n\n")

        super(msg)
      end
    end

    # Error raised when exposures depend on each other in a cycle.
    #
    # @api public
    # @since 3.1.0
    class CyclicExposureError < Error
      # Returns the names of the exposures in the cycle, starting and ending with the same name.
      #
      # @return [Array<Symbol>]
      #
      # @api public
      # @since 3.1.0
      attr_reader :cycle

      # @api private
      def initialize(cycle)
        @cycle = cycle
        super("exposures depend on each other in a cycle: #{cycle.join(' -> ')}")
      end
    end

    # Error raised when a rendering is required but not given.
    #
    # @api public
    # @since 2.1.0
    class RenderingMissingError < Error
      def message
        "a +rendering+ must be provided"
      end
    end
  end
end
