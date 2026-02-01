# frozen_string_literal: true

require "slim"

module Hanami
  class View
    module Tilt
      # @api private
      # @since 2.1.0
      module SlimAdapter
        # Add options to Slim::Engine to match the options from its default generator.
        #
        # The default generator for Slim::Engine is configurable via an engine option, like so:
        #
        # use(:Generator) { options[:generator] }
        #
        # Because this Temple filter is set as a proc, the resulting effect within Temple's EngineDSL
        # is that the generator's valid options are not merged into the full set of options available
        # on Slim::Engine itself. This means we receive a "Option :capture_generator is invalid"
        # warning when we set our `capture_generator:` below.
        #
        # However, this option is perfectly valid, so here we merge all the options for Slim's default
        # generator into the top-level engine's options, avoiding the warning.
        ::Slim::Engine.define_options(::Slim::Engine.options[:generator].options.valid_keys)

        # Slim template renderer for Hanami::View.
        #
        # This differs from the standard Slim::Template by automatically escaping HTML based on a
        # given string's `#html_safe?`, regardless of when "hanami/view/html" is required.
        #
        # @see Hanami::View::Tilt
        # @api private
        # @since 2.1.0
        Template = Temple::Templates::Tilt(
          ::Slim::Engine,
          use_html_safe: true,
          capture_generator: HTMLSafeStringBuffer
        )
      end
    end
  end
end
