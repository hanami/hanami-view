# frozen_string_literal: true

require "dry/core/equalizer"

module Hanami
  class View
    # @api private
    class Exposures
      include Dry::Equalizer(:exposures)

      # Cache key for the eager exposures and all their dependencies, which a render resolves before
      # it renders its template.
      EAGER_NAMES_CACHE_KEY = :eager_names
      private_constant :EAGER_NAMES_CACHE_KEY

      # Cache key for whether the exposures are free of dependency cycles, which a render checks
      # before it starts.
      ACYCLIC_CACHE_KEY = :acyclic
      private_constant :ACYCLIC_CACHE_KEY

      attr_reader :exposures

      def initialize(exposures = {}, cache: {})
        @exposures = exposures

        # Caches results worked out from the dependency graph between exposures, which every render
        # needs (see EAGER_NAMES_CACHE_KEY and ACYCLIC_CACHE_KEY). These depend only on which
        # exposures are in this set, not on a render's input. So we work each one out the first
        # time it's needed, and reuse it for every render after that.
        #
        # This cache shared with the bound exposures created for every view instance (see #bind), so
        # that the results worked out for one view instance can be reused by all of them.
        @cache = cache
      end

      def key?(name)
        exposures.key?(name)
      end

      def [](name)
        exposures[name]
      end

      def each(&block)
        exposures.each(&block)
      end

      def add(name, proc = nil, **options)
        # Replace rather than clear the cache, since it may be shared with bound exposures from
        # already-instantiated views. Those still have the old exposures, so must keep their own
        # cache.
        @cache = {}
        exposures[name] = Exposure.new(name, proc, **options)
      end

      def import(name, exposure)
        # Replace the cache, for the same reason as in #add.
        @cache = {}
        exposures[name] = exposure.dup
      end

      def bind(obj)
        bound_exposures = exposures.transform_values { |exposure|
          exposure.bind(obj)
        }

        self.class.new(bound_exposures, cache: @cache)
      end

      # Returns the names of the eager exposures, plus the names of their dependencies, all the way
      # down.
      #
      # Computed once per set of exposures, and shared with bound copies of the set.
      #
      # @return [Array<Symbol>]
      def eager_names
        @cache[EAGER_NAMES_CACHE_KEY] ||= begin
          names = {}
          exposures.each_value do |exposure|
            add_with_dependencies(exposure.name, names) if exposure.eager?
          end
          names.keys.freeze
        end
      end

      # Raises a {CyclicExposureError} if any exposures depend on each other in a cycle.
      #
      # Checks once per set of exposures, and shares the result with bound copies of the set.
      #
      # @raise [CyclicExposureError]
      def ensure_acyclic
        @cache[ACYCLIC_CACHE_KEY] ||= begin
          checked = {}
          exposures.each_key { |name| check_cycles(name, [], checked) }
          true
        end
      end

      private

      def add_with_dependencies(name, names)
        return if names.key?(name) || !key?(name)

        names[name] = true
        self[name].dependency_names.each { |dependency| add_with_dependencies(dependency, names) }
      end

      def check_cycles(name, path, checked)
        return if checked.key?(name) || !key?(name)

        if (index = path.index(name))
          raise CyclicExposureError.new(path[index..] + [name])
        end

        path.push(name)
        self[name].dependency_names.each { |dependency| check_cycles(dependency, path, checked) }
        path.pop

        checked[name] = true
      end
    end
  end
end
