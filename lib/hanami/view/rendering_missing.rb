# frozen_string_literal: true

require "dry/inflector"
require_relative "errors"

module Hanami
  class View
    # @api private
    # @since 2.1.0
    class RenderingMissing
      def format
        raise RenderingMissingError
      end

      def context
        raise RenderingMissingError
      end

      def part(_name, _value, **_options)
        raise RenderingMissingError
      end

      def scope(_name = nil, _locals) # rubocop:disable Style/OptionalArguments
        raise RenderingMissingError
      end

      def template(_name, _scope)
        raise RenderingMissingError
      end

      def partial(_name, _scope)
        raise RenderingMissingError
      end

      def inflector
        @inflector ||= Dry::Inflector.new
      end

      def current_template_name
        nil
      end

      def current_template_names
        EMPTY_TEMPLATE_NAMES
      end

      EMPTY_TEMPLATE_NAMES = [].freeze
      private_constant :EMPTY_TEMPLATE_NAMES
    end
  end
end
