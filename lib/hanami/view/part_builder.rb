# frozen_string_literal: true

module Hanami
  class View
    # Decorates exposure values with matching parts.
    #
    # @api public
    # @since 2.1.0
    class PartBuilder
      class << self
        # Decorates an exposure value.
        #
        # @param name [Symbol] exposure name
        # @param value [Object] exposure value
        # @param as [Symbol, nil] alternative name to use for part class resolution
        #
        # @return [Hanami::View::Part] decorated value
        #
        # @api public
        # @since 2.1.0
        def call(name, value, rendering:, as: nil)
          builder = value.respond_to?(:to_ary) ? :build_collection_part : :build_part

          send(builder, name: name, value: value, as: as, rendering: rendering)
        end

        private

        def build_part(name:, value:, as:, rendering:)
          klass = part_class(name: name, as: as, rendering: rendering)

          klass.new(name: name, value: value, rendering: rendering)
        end

        def build_collection_part(name:, value:, rendering:, as: nil)
          item_name, item_as = collection_item_name_as(name, as, inflector: rendering.inflector)
          item_part_class = part_class(name: item_name, as: item_as, rendering: rendering)

          arr = value.to_ary.map { |item|
            item_part_class.new(name: item_name, value: item, rendering: rendering)
          }

          collection_as = as.is_a?(Array) ? as.first : nil
          build_part(name: name, value: arr, as: collection_as, rendering: rendering)
        end

        def collection_item_name_as(name, as, inflector:)
          singular_name = inflector.singularize(name).to_sym
          singular_as =
            if as.is_a?(Array)
              as.last if as.length > 1
            else
              as
            end

          if singular_as && !singular_as.is_a?(Class)
            singular_as = inflector.singularize(singular_as.to_s)
          end

          [singular_name, singular_as]
        end

        def part_class(name:, as:, rendering:)
          name = as || name

          if name.is_a?(Class)
            name
          else
            View.cache.fetch_or_store(:part_class, name, rendering.config) do
              resolve_part_class(name: name, rendering: rendering)
            end
          end
        end

        def resolve_part_class(name:, rendering:)
          namespace = rendering.config.part_namespace
          return rendering.config.part_class unless namespace

          name = rendering.inflector.camelize(name.to_s)

          # Give autoloaders a chance to act
          begin
            klass = namespace.const_get(name)
          rescue NameError # rubocop:disable Lint/SuppressedException
          end

          if !klass && namespace.const_defined?(name, false)
            klass = namespace.const_get(name)
          end

          if klass && klass < Part
            klass
          else
            rendering.config.part_class
          end
        end
      end
    end
  end
end
