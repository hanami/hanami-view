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

      # Stack of names for the templates and partials currently being rendered. The top of the stack
      # is the innermost render in progress.
      #
      # @return [Array<String>]
      attr_reader :current_template_names

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
        @current_template_names = []
      end

      # Returns the name of the template or partial currently being rendered, or nil if no render
      # is in progress.
      #
      # For partials, this is the lookup name without the leading underscore (e.g. `"users/form"`,
      # not `"users/_form"`).
      #
      # @return [String, nil]
      def current_template_name
        @current_template_names.last
      end

      def template(name, scope, &block)
        @current_template_names.push(name.to_s)
        renderer.template(name, format, scope, &block)
      ensure
        @current_template_names.pop
      end

      def partial(name, scope, &block)
        @current_template_names.push(name.to_s)
        renderer.partial(name, format, scope, &block)
      ensure
        @current_template_names.pop
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
