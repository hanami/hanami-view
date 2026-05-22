# frozen_string_literal: true

module Hanami
  class View
    # Provides a baseline environment across all the templates, parts and scopes
    # in a given rendering.
    #
    # @abstract Subclass this and add your own methods (along with a custom
    #   `#initialize` if you wish to inject dependencies)
    #
    # @api public
    # @since 2.1.0
    class Context
      include DecoratedAttributes

      # @api private
      # @since 2.1.0
      attr_reader :_rendering

      # @api private
      # @since 2.1.0
      def self.new(rendering: RenderingMissing.new, **args)
        allocate.tap do |obj|
          obj.instance_variable_set(:@_rendering, rendering)
          obj.send(:initialize, **args)
        end
      end

      # Returns a new instance of Context
      #
      # @api public
      # @since 2.1.0
      def initialize(**)
      end

      # @api private
      # @since 2.1.0
      def dup_for_rendering(rendering)
        dup.tap do |obj|
          obj.instance_variable_set(:@_rendering, rendering)
        end
      end

      # Returns the name of the template or partial currently being rendered, or nil if no render is
      # in progress.
      #
      # @return [String, nil]
      #
      # @api public
      # @since x.x.x
      def current_template_name
        _rendering.current_template_name
      end
    end
  end
end
