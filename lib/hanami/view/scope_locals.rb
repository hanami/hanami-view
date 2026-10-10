# frozen_string_literal: true

module Hanami
  class View
    # The locals a scope class declares with {Scope.locals}.
    #
    # Checks the locals a scope is built with, raising an `ArgumentError` for any that are missing
    # or unknown, and fills in the defaults for the rest. The messages follow Ruby's own for keyword
    # arguments, as fixed locals in templates do.
    #
    # @api private
    # @since 3.1.0
    class ScopeLocals
      # @param required [Array<Symbol>] locals the scope must be given
      # @param defaults [Hash{Symbol => Object}] locals the scope may be given, with their defaults
      #
      # @api private
      # @since 3.1.0
      def initialize(required:, defaults:)
        @required = required.map(&:to_sym).freeze
        @defaults = defaults.transform_keys(&:to_sym).freeze
      end

      # Returns the locals, keyed by Symbol, with defaults filled in.
      #
      # @param locals [Hash{Symbol, String => Object}]
      # @param scope_class [Class] the scope class being built, named in error messages
      #
      # @return [Hash{Symbol => Object}]
      #
      # @raise [ArgumentError] if a required local is missing, or a local is not declared
      #
      # @api private
      # @since 3.1.0
      def call(locals, scope_class:)
        locals = locals.transform_keys(&:to_sym)
        missing = @required - locals.keys
        unknown = locals.keys - @required - @defaults.keys

        raise ArgumentError, message("missing", missing, scope_class) if missing.any?
        raise ArgumentError, message("unknown", unknown, scope_class) if unknown.any?

        @defaults.merge(locals)
      end

      private

      def message(kind, names, scope_class)
        noun = names.one? ? "local" : "locals"
        "#{kind} #{noun}: #{names.map(&:inspect).join(", ")} for #{scope_class.name || scope_class.inspect}"
      end
    end
  end
end
