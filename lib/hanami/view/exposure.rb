# frozen_string_literal: true

require "dry/core/equalizer"

module Hanami
  class View
    # An exposure defined on a view
    #
    # @api private
    # @since 2.1.0
    class Exposure
      include Dry::Equalizer(:name, :proc, :object, :options)

      EXPOSURE_DEPENDENCY_PARAMETER_TYPES = %i[req opt].freeze
      INPUT_PARAMETER_TYPES = %i[key keyreq keyrest].freeze

      # @api private
      # @since 2.1.0
      attr_reader :name

      # @api private
      # @since 2.1.0
      attr_reader :proc

      # @api private
      # @since 2.1.0
      attr_reader :object

      # @api private
      # @since 2.1.0
      attr_reader :options

      # @api private
      # @since 2.1.0
      def initialize(name, proc = nil, object = nil, **options)
        @name = name
        @proc = prepare_proc(proc, object)
        @object = object
        @options = options
      end

      # @api private
      # @since 2.1.0
      def bind(obj)
        self.class.new(name, proc, obj, **options)
      end

      # @api private
      # @since 2.1.0
      def dependency_names
        @dependency_names ||=
          if proc
            proc.parameters.each_with_object([]) { |(type, name), names|
              names << name if EXPOSURE_DEPENDENCY_PARAMETER_TYPES.include?(type)
            }
          else
            []
          end
      end

      # @api private
      # @since 2.1.0
      def dependencies?
        !dependency_names.empty?
      end

      # @api private
      # @since 2.1.0
      def input_keys
        @input_keys ||=
          if proc
            proc.parameters.each_with_object([]) { |(type, name), keys|
              keys << name if INPUT_PARAMETER_TYPES.include?(type)
            }
          else
            []
          end
      end

      # @api private
      # @since 2.1.0
      def for_layout?
        options.fetch(:layout, false)
      end

      # @api private
      # @since 2.1.0
      def decorate?
        options.fetch(:decorate, true)
      end

      # @api private
      # @since 2.1.0
      def private?
        options.fetch(:private, false)
      end

      # @api private
      # @since 2.1.0
      def default_value
        options[:default]
      end

      # @api private
      # @since 2.1.0
      def call(input, locals = {})
        if proc
          call_proc(input, locals)
        else
          input.fetch(name) { default_value }
        end
      end

      private

      def call_proc(input, locals)
        args, keywords = proc_args(input, locals)

        if keywords.empty?
          if proc.is_a?(Method)
            proc.(*args)
          else
            object.instance_exec(*args, &proc)
          end
        else
          if proc.is_a?(Method)
            proc.(*args, **keywords)
          else
            object.instance_exec(*args, **keywords, &proc)
          end
        end
      end

      def proc_args(input, locals)
        dependency_args = proc_dependency_args(locals)
        keywords = proc_input_args(input)

        if keywords.empty?
          [dependency_args, {}]
        else
          [dependency_args, keywords]
        end
      end

      def proc_dependency_args(locals)
        dependency_names.map { |name| locals.fetch(name) }
      end

      def proc_input_args(input)
        if proc.parameters.any? { |(type, _name)| type == :keyrest }
          input.except(:context)
        else
          input_keys.each_with_object({}) { |key, args|
            args[key] = input[key] if input.key?(key)
          }
        end
      end

      def prepare_proc(proc, object)
        if proc
          proc
        elsif object.respond_to?(name, _include_private = true)
          object.method(name)
        end
      end
    end
  end
end
