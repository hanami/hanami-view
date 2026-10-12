# frozen_string_literal: true

require "dry/core/equalizer"

module Hanami
  class View
    # @api private
    class Exposures
      include Dry::Equalizer(:exposures)

      # The names of exposures that every render needs, worked out from the exposures and the
      # dependencies between them.
      #
      # @api private
      Names = Data.define(:eager, :public, :layout)
      private_constant :Names

      attr_reader :exposures

      # @raise [CyclicExposureError] if the exposures depend on each other in a cycle
      def initialize(exposures = {})
        @exposures = exposures

        # Exposures defined as methods have their dependencies only once bound (see #bind), which
        # happens when a view is initialized. This is our first best time to check for cycles. It
        # also fits well for front-loading the checks when apps are eager loading views.
        ensure_acyclic

        @names = build_names
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
        exposures[name] = Exposure.new(name, proc, **options)
        @names = nil
      end

      def import(name, exposure)
        exposures[name] = exposure.dup
        @names = nil
      end

      def bind(obj)
        bound_exposures = exposures.transform_values { |exposure|
          exposure.bind(obj)
        }

        self.class.new(bound_exposures.freeze).freeze
      end

      # Returns the names of the eager exposures, plus the names of their dependencies, all the way
      # down.
      #
      # @return [Array<Symbol>]
      def eager_names
        names.eager
      end

      # Returns the names of the public (non-private) exposures.
      #
      # @return [Set<Symbol>]
      def public_names
        names.public
      end

      # Returns the names of the public exposures marked with `layout: true`.
      #
      # @return [Set<Symbol>]
      def layout_names
        names.layout
      end

      private

      # Returns the names used by {#eager_names}, {#public_names} and {#layout_names}.
      #
      # During exposure definition, these names are cleared by {#add} or {#import}. In this case, it
      # builds and returns them without storing them.
      #
      # When bound exposures are created for a view instance (via {#bind}), names are built and
      # stored, and the exposures frozen, which keeps them for the full lifetime of the view.
      def names = @names || build_names

      def build_names
        eager = {}
        exposures.each_value do |exposure|
          add_with_dependencies(exposure.name, eager) if exposure.eager?
        end

        public = exposures.each_value.reject(&:private?).to_set(&:name)
        layout = exposures.each_value.select { public.include?(_1.name) && _1.for_layout? }.to_set(&:name)

        Names.new(eager: eager.keys.freeze, public: public.freeze, layout: layout.freeze)
      end

      def add_with_dependencies(name, names)
        return if names.key?(name) || !key?(name)

        names[name] = true
        self[name].dependency_names.each { |dependency| add_with_dependencies(dependency, names) }
      end

      def ensure_acyclic
        checked = {}
        exposures.each_key { |name| check_cycles(name, [], checked) }
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
