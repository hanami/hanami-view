# frozen_string_literal: true

require "tilt"

module Hanami
  class View
    # @api private
    # @since 2.1.0
    module Tilt
      # @api private
      # @since 2.1.0
      Mapping = ::Tilt.default_mapping.dup.tap { |mapping|
        # Unregister any existing mappings for the extensions we provide our own engines for.
        #
        # Tilt preferences non-lazy registrations over lazy ones (see `Tilt::Mapping#lookup`). So if
        # "haml" or "slim" has been required before this mapping is built (each of which registers
        # its own non-lazy mapping with Tilt), our own lazy-registered adapters below would be
        # shadowed and never picked up, and templates would render without our specific required
        # behavior.
        #
        # Unregistering first ensures our engines are always used, regardless of load order.
        mapping.unregister "erb", "rhtml", "haml", "slim"

        # Register our own ERB template.
        mapping.register_lazy "Hanami::View::ERB::Template", "hanami/view/erb/template", "erb", "rhtml"

        # Register templates for Haml and Slim that set the `use_html_safe: true` option.
        #
        # We register these lazily so that the optional "haml" and "slim" gems only need to be
        # installed when their templates are actually used.
        #
        # Our template namespaces below have the "Adapter" suffix to work around a bug in Tilt's
        # `Mapping#const_defined?`, which (if slim was already required) would receive
        # "Hanami::View::Slim::Template" and return `Slim::Template`, which is the opposite of what
        # we want.
        mapping.register_lazy "Hanami::View::Tilt::HamlAdapter::Template", "hanami/view/tilt/haml_adapter", "haml"
        mapping.register_lazy "Hanami::View::Tilt::SlimAdapter::Template", "hanami/view/tilt/slim_adapter", "slim"
      }

      class << self
        # @api private
        # @since 2.1.0
        def [](path, mapping, options)
          with_mapping(mapping).new(path, options)
        end

        private

        def with_mapping(mapping)
          View.cache.fetch_or_store(:tilt_mapping, mapping) {
            if mapping.any?
              build_mapping(mapping)
            else
              Mapping
            end
          }
        end

        def build_mapping(mapping)
          Mapping.dup.tap do |new_mapping|
            mapping.each do |extension, template_class|
              new_mapping.register template_class, extension
            end
          end
        end
      end
    end
  end
end
