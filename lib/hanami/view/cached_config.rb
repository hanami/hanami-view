# frozen_string_literal: true

module Hanami
  class View
    # A frozen snapshot of resolved {View} configuration values.
    #
    # Built once per {View} subclass after `config.finalize!`, then read on the rendering hot path
    # in place of `config.foo` calls (which dispatch through dry-configurable's `method_missing`
    # and allocate strings on every read).
    #
    # @api private
    # @since 2.3.0
    CachedConfig = Data.define(
      :paths,
      :template,
      :layout,
      :layouts_dir,
      :default_format,
      :default_context,
      :scope,
      :scope_class,
      :scope_namespace,
      :part_class,
      :part_namespace,
      :inflector,
      :part_builder,
      :scope_builder,
      :renderer_engine_mapping,
      :renderer_options,
    ) do
      def self.from_config(config)
        new(
          paths: config.paths,
          template: config.template,
          layout: config.layout,
          layouts_dir: config.layouts_dir,
          default_format: config.default_format,
          default_context: config.default_context,
          scope: config.scope,
          scope_class: config.scope_class,
          scope_namespace: config.scope_namespace,
          part_class: config.part_class,
          part_namespace: config.part_namespace,
          inflector: config.inflector,
          part_builder: config.part_builder,
          scope_builder: config.scope_builder,
          renderer_engine_mapping: config.renderer_engine_mapping,
          renderer_options: config.renderer_options,
        )
      end

      # Identity-based hash and equality. Each {View} subclass memoizes a single instance, so
      # identity matches the intended "same cache instance = same key" semantics for use as a
      # `View.cache` lookup key — and avoids walking all 16 members on every render.
      def hash
        object_id
      end

      def eql?(other)
        equal?(other)
      end
      alias_method :==, :eql?
    end
  end
end
