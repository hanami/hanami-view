# frozen_string_literal: true

require "pathname"
require_relative "errors"

module Hanami
  class View
    # Resolves a template by name and renders it through Tilt.
    #
    # Template lookup combines two pieces of state:
    #
    # - **`config.paths`** — the configured view paths, immutable for the lifetime of the
    #   renderer. When multiple view paths are configured, earlier ones override later ones.
    # - **`@prefixes`** — a stack of subdirectories within each view path to search, mutated
    #   during rendering. It starts at `[CURRENT_PATH_PREFIX]` (the root itself). When a template is
    #   rendered, its parent directory (e.g. `"users"` for `"users/index"`) is pushed onto the stack
    #   so that a partial referenced by its bare name (e.g. `render("form")` from inside
    #   `users/index.html.erb`) can be found alongside the template that renders it. The stack is
    #    snapshot-and-restored around each render via `ensure`.
    #
    # `#lookup` tries every combination of a path and a prefix, joining each pair with the
    # requested name to find a matching file. `paths` are checked in configured order; an earlier
    # entry overrides a later one. `prefixes` are checked oldest-first: a partial at the root
    # wins over a same-named partial in a directory pushed onto the stack mid-render. First match
    # wins.
    #
    # @api private
    class Renderer
      PARTIAL_PREFIX = "_"
      PATH_DELIMITER = "/"
      CURRENT_PATH_PREFIX = "."

      # Matches the `.format.engine` extensions on a template path (e.g. `.html.erb`).
      EXTENSIONS_REGEXP = /\.[^.\/]+\.[^.\/]+\z/

      # Stack of resolved names for the templates and partials currently being rendered. The top of
      # the stack is the innermost render in progress.
      #
      # @return [Array<String>]
      attr_reader :current_template_names

      # @api private
      def initialize(config_data)
        @config_data = config_data
        @prefixes = [CURRENT_PATH_PREFIX]
        @current_template_names = []
      end

      # Returns the resolved name of the template or partial currently being rendered, or nil if no
      # render is in progress.
      #
      # The name is the file's path relative to the matching view path, with format/engine
      # extensions stripped.
      #
      # @return [String, nil]
      def current_template_name
        @current_template_names.last
      end

      def template(name, format, scope, &block)
        old_prefixes = @prefixes.dup

        result = lookup(name, format)
        raise TemplateNotFoundError.new(name, format, config_data.paths) unless result

        template_path, relative_path = result

        new_prefix = File.dirname(name)
        @prefixes << new_prefix unless @prefixes.include?(new_prefix)
        @current_template_names << resolve_template_name(relative_path)

        render(template_path, scope, &block)
      ensure
        @prefixes = old_prefixes
        @current_template_names.pop if result
      end

      def partial(name, format, scope, &block)
        template(name_for_partial(name), format, scope, &block)
      end

      private

      attr_reader :config_data, :prefixes

      # Searches `config.paths` (under each of the `prefixes`) for a template matching `name` and
      # `format`. Returns the template's absolute file path (for rendering via Tilt) together with
      # its path relative to the matching view path.
      #
      # Results are memoized via `View.cache` keyed on `(name, format, config_data, prefixes)`.
      #
      # @return [[String, String], nil]
      def lookup(name, format)
        View.cache.fetch_or_store(:lookup, name, format, config_data.object_id, prefixes) {
          catch :found do
            config_data.paths.each do |path|
              prefixes.each do |prefix|
                file_path = path.lookup(prefix, name, format)
                if file_path
                  relative_path = Pathname.new(file_path).relative_path_from(path.dir).to_s
                  throw :found, [file_path, relative_path]
                end
              end
            end
            nil
          end
        }
      end

      # Derives the rendered template's name from its relative path, suitable for tracking on
      # `@current_template_names` and surfacing via `#current_template_name`.
      #
      # Strips format/engine extensions (e.g. `.html.erb`), so `"posts/_form.html.erb"` becomes
      # `"posts/_form"`.
      #
      # @return [String]
      def resolve_template_name(relative_path)
        relative_path.sub(EXTENSIONS_REGEXP, "")
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
