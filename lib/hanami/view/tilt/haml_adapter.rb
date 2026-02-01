# frozen_string_literal: true

require "haml"

module Hanami
  class View
    module Tilt
      # @api private
      # @since 2.1.0
      module HamlAdapter
        # Add options to Haml::Engine to match the options from its default generator.
        #
        # The default generator for Haml::Engine is configurable via an engine option, like so:
        #
        # use :Generator, -> { options[:generator] }
        #
        # Because this Temple filter is set as a proc, the resulting effect within Temple's EngineDSL
        # is that the generator's valid options are not merged into the full set of options available
        # on Haml::Engine itself. This means we receive a "Option :capture_generator is invalid"
        # warning when we set our `capture_generator:` below.
        #
        # However, this option is perfectly valid, so here we merge all the options for Haml's default
        # generator into the top-level engine's options, avoiding the warning.
        ::Haml::Engine.define_options(::Haml::Engine.options[:generator].options.valid_keys)

        # Haml template renderer for Hanami::View.
        #
        # This differs from the standard Haml::Template by automatically escaping HTML based on a
        # given string's `#html_safe?`, regardless of when "hanami/view/html" is required.
        #
        # @see Hanami::View::Tilt
        # @api private
        # @since 2.1.0
        Template = Temple::Templates::Tilt(
          ::Haml::Engine,
          use_html_safe: true,
          capture_generator: HTMLSafeStringBuffer
        )
      end
    end
  end
end
