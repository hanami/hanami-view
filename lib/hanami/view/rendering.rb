# frozen_string_literal: true

module Hanami
  class View
    # @api private
    class Rendering
      # @api private
      attr_reader :format

      # @api private
      attr_reader :inflector, :part_builder, :scope_builder

      # @api private
      attr_reader :part_class, :part_namespace, :scope_class, :scope_namespace

      # Stable identity for the underlying config snapshot.
      #
      # @api private
      attr_reader :cache_key

      # @api private
      attr_reader :context, :renderer

      # @api private
      def initialize(config_data:, format:, context:)
        @format = format

        @inflector = config_data.inflector
        @part_builder = config_data.part_builder
        @scope_builder = config_data.scope_builder

        @part_class = config_data.part_class
        @part_namespace = config_data.part_namespace
        @scope_class = config_data.scope_class
        @scope_namespace = config_data.scope_namespace
        @cache_key = config_data.object_id

        @context = context.dup_for_rendering(self)
        @renderer = Renderer.new(config_data)
      end

      # @api private
      def template(name, scope, &block)
        renderer.template(name, format, scope, &block)
      end

      # @api private
      def partial(name, scope, &block)
        renderer.partial(name, format, scope, &block)
      end

      # @api private
      def part(name, value, as: nil)
        part_builder.(name, value, as: as, rendering: self)
      end

      # @api private
      def scope(name = nil, locals) # rubocop:disable Style/OptionalArguments
        scope_builder.(name, locals: locals, rendering: self)
      end
    end
  end
end
