# frozen_string_literal: true

module Hanami
  class View
    # @api private
    # @since 2.1.0
    class Rendering
      # @api private
      # @since 2.1.0
      attr_reader :config, :format

      # @api private
      # @since 2.3.0
      attr_reader :cached_config

      # @api private
      # @since 2.1.0
      attr_reader :inflector, :part_builder, :scope_builder

      # @api private
      # @since 2.1.0
      attr_reader :context, :renderer

      # @api private
      # @since 2.1.0
      def initialize(config:, format:, context:, cached_config: nil)
        cached_config ||= CachedConfig.from_config(config)

        @config = config
        @cached_config = cached_config
        @format = format

        @inflector = cached_config.inflector
        @part_builder = cached_config.part_builder
        @scope_builder = cached_config.scope_builder

        @context = context.dup_for_rendering(self)
        @renderer = Renderer.new(cached_config)
      end

      # @api private
      # @since 2.1.0
      def template(name, scope, &block)
        renderer.template(name, format, scope, &block)
      end

      # @api private
      # @since 2.1.0
      def partial(name, scope, &block)
        renderer.partial(name, format, scope, &block)
      end

      # @api private
      # @since 2.1.0
      def part(name, value, as: nil)
        part_builder.(name, value, as: as, rendering: self)
      end

      # @api private
      # @since 2.1.0
      def scope(name = nil, locals) # rubocop:disable Style/OptionalArguments
        scope_builder.(name, locals: locals, rendering: self)
      end
    end
  end
end
