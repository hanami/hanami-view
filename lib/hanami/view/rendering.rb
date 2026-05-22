# frozen_string_literal: true

module Hanami
  class View
    # @api private
    class Rendering
      # @api private
      attr_reader :format

      attr_reader :inflector, :part_builder, :scope_builder

      attr_reader :part_class, :part_namespace, :scope_class, :scope_namespace

      # Stable identity for the underlying config snapshot.
      attr_reader :cache_key

      attr_reader :context, :renderer

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

      # Returns the resolved name of the template or partial currently being rendered, or nil if
      # no render is in progress.
      #
      # @return [String, nil]
      #
      # @api public
      # @since x.x.x
      def current_template_name
        renderer.current_template_name
      end

      # Returns the stack of resolved names for the templates and partials currently being
      # rendered.
      #
      # @return [Array<String>]
      #
      # @api private
      # @since x.x.x
      def current_template_names
        renderer.current_template_names
      end

      def template(name, scope, &block)
        renderer.template(name, format, scope, &block)
      end

      def partial(name, scope, &block)
        renderer.partial(name, format, scope, &block)
      end

      def part(name, value, as: nil)
        part_builder.(name, value, as: as, rendering: self)
      end

      def scope(name = nil, locals) # rubocop:disable Style/OptionalArguments
        scope_builder.(name, locals: locals, rendering: self)
      end
    end
  end
end
