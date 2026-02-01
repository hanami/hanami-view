# frozen_string_literal: true

module Hanami
  class View
    # Builds scope objects via matching classes
    #
    # @api public
    # @since 2.1.0
    class ScopeBuilder
      class << self
        # Returns a new scope using a class matching the name.
        #
        # @param name [Symbol, Class] scope name
        # @param locals [Hash<Symbol, Object>] locals hash
        #
        # @return [Hanami::View::Scope]
        #
        # @api public
        # @since 2.1.0
        def call(name = nil, locals:, rendering:)
          klass = scope_class(name, rendering: rendering)

          klass.new(name: name, locals: locals, rendering: rendering)
        end

        private

        def scope_class(name = nil, rendering:)
          if name.nil?
            rendering.config.scope_class
          elsif name.is_a?(Class)
            name
          else
            View.cache.fetch_or_store(name, rendering.config) do
              resolve_scope_class(name: name, rendering: rendering)
            end
          end
        end

        def resolve_scope_class(name:, rendering:)
          name = rendering.inflector.camelize(name.to_s)

          namespace = rendering.config.scope_namespace

          # Give autoloaders a chance to act
          begin
            klass = namespace.const_get(name)
          rescue NameError # rubocop:disable Lint/SuppressedException
          end

          if !klass && namespace.const_defined?(name, false)
            klass = namespace.const_get(name)
          end

          if klass && klass < Scope
            klass
          else
            rendering.config.scope_class
          end
        end
      end
    end
  end
end
