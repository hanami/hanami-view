# frozen_string_literal: true

require_relative "errors"

module Hanami
  class View
    # @api private
    class Renderer
      # @api private
      PARTIAL_PREFIX = "_"

      # @api private
      PATH_DELIMITER = "/"

      # @api private
      CURRENT_PATH_PREFIX = "."

      # @api private
      def initialize(config_data)
        @config_data = config_data
        @prefixes = [CURRENT_PATH_PREFIX]
      end

      # @api private
      def template(name, format, scope, &block)
        old_prefixes = @prefixes.dup

        template_path = lookup(name, format)

        raise TemplateNotFoundError.new(name, format, config_data.paths) unless template_path

        new_prefix = File.dirname(name)
        @prefixes << new_prefix unless @prefixes.include?(new_prefix)

        render(template_path, scope, &block)
      ensure
        @prefixes = old_prefixes
      end

      # @api private
      def partial(name, format, scope, &block)
        template(name_for_partial(name), format, scope, &block)
      end

      private

      attr_reader :config_data, :prefixes

      def lookup(name, format)
        View.cache.fetch_or_store(:lookup, name, format, config_data.object_id, prefixes) {
          catch :found do
            config_data.paths.reduce(nil) do |_, path|
              prefixes.reduce(nil) do |_, prefix|
                result = path.lookup(prefix, name, format)
                throw :found, result if result
              end
            end
          end
        }
      end

      def name_for_partial(name)
        segments = name.to_s.split(PATH_DELIMITER)
        segments[-1] = "#{PARTIAL_PREFIX}#{segments[-1]}"
        segments.join(PATH_DELIMITER)
      end

      def render(path, scope, &block)
        tilt(path).render(scope, {locals: scope._locals}, &block).html_safe
      end

      def tilt(path)
        View.cache.fetch_or_store(:tilt, path, config_data.object_id) {
          Hanami::View::Tilt[path, config_data.renderer_engine_mapping, config_data.renderer_options]
        }
      end
    end
  end
end
