# frozen_string_literal: true

require "dry/core/constants"

module Hanami
  class View
    # The locals for a view rendering.
    #
    # Locals are resolved lazily. Each exposure is called (and its value decorated) only when its
    # value is first read, then memoized for the rest of the rendering.
    #
    # Reading a local via {#[]} or {#fetch} resolves only that exposure and its dependencies.
    # {#to_h} resolves every exposure.
    #
    # @api public
    # @since 3.1.0
    class Locals
      # @api private
      Undefined = Dry::Core::Constants::Undefined
      private_constant :Undefined

      # Returns a new Locals.
      #
      # @param exposures [Exposures] the bound exposures
      # @param input [Hash] the view's input
      # @param decorator [#call, nil] optional callable, called with the value and the exposure,
      #   returning the value to provide as the local
      # @param keys [Set<Symbol>, nil] the names of the locals; defaults to every public exposure
      # @param resolved [Hash] resolved values; give another Locals' resolved values to share them
      #
      # @api private
      def initialize(exposures, input, decorator: nil, keys: nil, resolved: {})
        @exposures = exposures
        @input = input
        @decorator = decorator
        @keys = keys || exposures.public_names
        @resolved = resolved
      end

      # Returns true if there is a local with the given name. Does not resolve any exposures.
      #
      # @param name [Symbol] local name
      #
      # @return [Boolean]
      #
      # @api public
      # @since 3.1.0
      def key?(key)
        @keys.include?(key)
      end

      # Returns the value of the local with the given name, or nil if there is no such local.
      #
      # Resolves the matching exposure (and its dependencies) only.
      #
      # @param name [Symbol] local name
      #
      # @return [Object, nil]
      #
      # @api public
      # @since 3.1.0
      def [](key)
        resolve(key) if key?(key)
      end

      # Returns the value of the local with the given name.
      #
      # Resolves the matching exposure (and its dependencies) only.
      #
      # Behaves like `Hash#fetch` when there is no such local: returns the given default, or the
      # result of the given block, or raises a `KeyError`.
      #
      # @param key [Symbol] local name
      # @param default [Object] optional default value
      #
      # @return [Object]
      #
      # @raise [KeyError] if there is no such local, and no default or block is given
      #
      # @api public
      # @since 3.1.0
      def fetch(key, default = Undefined)
        if key?(key)
          resolve(key)
        elsif block_given?
          yield key
        elsif !default.equal?(Undefined)
          default
        else
          raise KeyError.new("key not found: #{key.inspect}", receiver: self, key:)
        end
      end

      # Returns a hash of all the locals.
      #
      # Resolves every exposure.
      #
      # @return [Hash{Symbol => Object}]
      #
      # @api public
      # @since 3.1.0
      def to_h
        @keys.each.with_object({}) { |key, hsh| hsh[key] = resolve(key) }
      end

      # Returns a string for debugging. Does not resolve any exposures.
      #
      # @return [String]
      #
      # @api public
      # @since 3.1.0
      def inspect
        "#<#{self.class.name} keys=#{@keys.to_a.inspect}>"
      end

      # Returns a filtered view of these locals, containing only the exposures marked with
      # `layout: true`. Shares resolved values with these locals.
      #
      # @return [Locals]
      #
      # @api private
      def for_layout
        self.class.new(
          @exposures,
          @input,
          decorator: @decorator,
          keys: @exposures.layout_names,
          resolved: @resolved
        )
      end

      # Resolves every eager exposure along with its dependencies.
      #
      # @return [self]
      #
      # @api private
      def resolve_eager
        @exposures.eager_names.each { |name| resolve(name) }
        self
      end

      private

      def resolve(key)
        return @resolved[key] if @resolved.key?(key)

        exposure = @exposures[key]
        raise KeyError.new("key not found: #{key.inspect}", receiver: self, key:) unless exposure

        dependencies = exposure.dependency_names.to_h { |dependency_name|
          [dependency_name, resolve(dependency_name)]
        }

        value = exposure.call(@input, dependencies)
        value = @decorator.call(value, exposure) if @decorator

        @resolved[key] = value
      end
    end
  end
end
