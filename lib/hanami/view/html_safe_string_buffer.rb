# frozen_string_literal: true

require "temple"

module Hanami
  class View
    # Specialized Temple buffer class that marks block-captured strings as HTML safe.
    #
    # This is important for any scope or part methods that receive a string from a yielded block
    # and then determine whether to escape that string based on its `.html_safe?` value.
    #
    # In this case, since blocks captured templates _intentionally_ contain HTML (this is the
    # purpose of the template after all), it makes sense to mark the entire captured block string as
    # HTML safe.
    #
    # This is compatible with escaping of values interpolated into the template, since those will
    # have already been automatically escaped by the template engine when they are evaluated, before
    # the overall block is captured.
    #
    # This filter is included in all three of our supported HTML template engines (ERB, Haml and
    # Slim) to provide consistent behavior across all.
    #
    # @see Hanami::View::ERB::Engine
    # @see Hanami::View::HamlAdapter::Template
    # @see Hanami::View::SlimAdapter::Template
    #
    # @api private
    # @since 2.1.0
    class HTMLSafeStringBuffer < Temple::Generators::StringBuffer
      # Replace `Temple::Generator::ArrayBuffer#call` (which is used via the superclass of
      # `StringBuffer`) with the standard implementation from the base `Temple::Generator`.
      #
      # This avoids certain specialisations in `ArrayBuffer#call` that prevent `#return_buffer` from
      # being called. For our needs, `#return_buffer` must be called at all times in order to ensure
      # the captured string is consistently marked as `.html_safe`.
      def call(exp)
        [preamble, compile(exp), postamble].flatten.compact.join("; ")
      end

      # Marks the string returned from the captured buffer as HTML safe.
      def return_buffer
        "#{buffer}.html_safe"
      end
    end
  end
end
