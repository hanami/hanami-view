# frozen_string_literal: true

require "temple"
require "uri"

module Hanami
  class View
    module Helpers
      # Helper methods for escaping content for safely including in HTML.
      #
      # When using full Hanami apps, these helpers will be automatically available in your view
      # templates, part classes and scope classes.
      #
      # When using hanami-view standalone, include this module directly in your base part and scope
      # classes, or in specific classes as required.
      #
      # @example Standalone usage
      #   class BasePart < Hanami::View::Part
      #     include Hanami::View::Helpers::EscapeHelper
      #   end
      #
      #   class BaseScope < Hanami::View::Scope
      #     include Hanami::View::Helpers::EscapeHelper
      #   end
      #
      #   class BaseView < Hanami::View
      #     config.part_class = BasePart
      #     config.scope_class = BaseScope
      #   end
      #
      # @api public
      # @since 2.1.0
      module EscapeHelper
        extend self

        # Returns an escaped string that is safe to include in HTML.
        #
        # Use this helper when including any untrusted user input in your view content.
        #
        # If the given string is already marked as HTML safe, then it will be returned without
        # escaping.
        #
        # Marks the escaped string marked as HTML safe, ensuring it will not be escaped again.
        #
        # @param input [String] the input string
        # @return [Hanami::View::HTML::SafeString] the escaped string
        #
        # @example
        #   escape_html("Safe content")
        #   # => "Safe content"
        #
        #   escape_html("<script>alert('xss')</script>")
        #   # => "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
        #
        #   escape_html(raw("<p>Not escaped</p>"))
        #   # => "<p>Not escaped</p>"
        #
        # @api public
        # @since 2.1.0
        def escape_html(input)
          Temple::Utils.escape_html_safe(input)
        end

        # @api public
        # @since 2.1.0
        alias_method :h, :escape_html

        # Returns an escaped string from joining the elements in a given array.
        #
        # Behaves similarly to `Array#join`. The given array is flattened, and all items, including
        # the supplied separator, are HTML escaped unless they are already HTML safe.
        #
        # Marks the returned string as HTML safe, ensuring it will not be escaped again.
        #
        # @param array [Array<#to_s>] the array
        # @param separator[String] the separator for the joined string
        # @return [Hanami::View::HTML::SafeString] the escaped string
        #
        # @example
        #   safe_join([raw("<p>foo</p>"), "<p>bar</p>"], "<br>")
        #   # => "<p>foo</p>&lt;br&gt;&lt;p&gt;bar&lt;/p&gt;"
        #
        #   safe_join([raw("<p>foo</p>"), raw("<p>bar</p>")], raw("<br>"))
        #   # => "<p>foo</p><br><p>bar</p>"
        #
        # @see #escape_html
        #
        # @api public
        # @since 2.1.0
        def escape_join(array, separator = $,)
          separator = escape_html(separator)

          array.flatten.map! { |i| escape_html(i) }.join(separator).html_safe
        end

        # Returns a the given URL string if it has one of the permitted URL schemes. For URLs with
        # non-permitted schemes, returns an empty string.
        #
        # Use this method when including URLs from untrusted user input in your view content.
        #
        # The default permitted schemes are:
        # - `http`
        # - `https`
        # - `mailto`
        #
        # @param input [String] the URL string
        # @param permitted_schemes [Array<string>] an optional array of permitted schemes
        #
        # @return [String] the permitted URL, or empty string
        #
        # @example
        #   sanitize_url("https://hanamirb.org")    # => "http://hanamirb.org"
        #   sanitize_url("javascript:alert('xss')") # => ""
        #
        #   sanitize_url("gemini://gemini.circumlunar.space/", %w[http https gemini])
        #   # => "gemini://gemini.circumlunar.space/"
        #
        # @api public
        # @since 2.1.0
        def sanitize_url(input, permitted_schemes = PERMITTED_URL_SCHEMES)
          return input if input.html_safe?

          URI_PARSER.extract(
            URI.decode_www_form_component(input.to_s),
            permitted_schemes
          ).first.to_s.html_safe
        end

        # Use the RFC2396_PARSER if available. Modern Rubies should have RFC2396_PARSER available.
        # Otherwise, fall back to the DEFAULT_PARSER (which may still raise deprecation warnings).
        #
        # @api private
        URI_PARSER = URI.const_defined?(:RFC2396_PARSER) ? URI::RFC2396_PARSER : URI::DEFAULT_PARSER
        private_constant :URI_PARSER

        # @api private
        # @since 2.1.0
        PERMITTED_URL_SCHEMES = %w[http https mailto].freeze
        private_constant :PERMITTED_URL_SCHEMES

        # Returns an escaped name from the given string, intended for use as an XML tag or attribute
        # name.
        #
        # Replaces non-safe characters with an underscore.
        #
        # Follows the requirements of the [XML specification](https://www.w3.org/TR/REC-xml/#NT-Name).
        #
        # @example
        #   escape_xml_name("1 < 2 & 3") # => "1___2___3"
        #
        # @api public
        # @since 2.1.0
        def escape_xml_name(name)
          name = name.to_s
          return "" if name.match?(BLANK_STRING_REGEXP)
          return name if name.match?(SAFE_XML_TAG_NAME_REGEXP)

          starting_char = name[0]
          starting_char.gsub!(INVALID_TAG_NAME_START_REGEXP, TAG_NAME_REPLACEMENT_CHAR)

          return starting_char if name.size == 1

          following_chars = name[1..-1]
          following_chars.gsub!(INVALID_TAG_NAME_FOLLOWING_REGEXP, TAG_NAME_REPLACEMENT_CHAR)

          starting_char << following_chars
        end

        # @api private
        # @since 2.1.0
        BLANK_STRING_REGEXP = /\A\s*\z/

        # Following XML requirements: https://www.w3.org/TR/REC-xml/#NT-Name
        # @api private
        # @since 2.1.0
        TAG_NAME_START_CODEPOINTS = \
          "@:A-Z_a-z\u{C0}-\u{D6}\u{D8}-\u{F6}\u{F8}-\u{2FF}\u{370}-\u{37D}\u{37F}-\u{1FFF}" \
          "\u{200C}-\u{200D}\u{2070}-\u{218F}\u{2C00}-\u{2FEF}\u{3001}-\u{D7FF}\u{F900}-\u{FDCF}" \
          "\u{FDF0}-\u{FFFD}\u{10000}-\u{EFFFF}"
        private_constant :TAG_NAME_START_CODEPOINTS

        # @api private
        # @since 2.1.0
        INVALID_TAG_NAME_START_REGEXP = /[^#{TAG_NAME_START_CODEPOINTS}]/
        private_constant :INVALID_TAG_NAME_START_REGEXP

        # @api private
        # @since 2.1.0
        TAG_NAME_FOLLOWING_CODEPOINTS = "#{TAG_NAME_START_CODEPOINTS}\\-.0-9\u{B7}\u{0300}-\u{036F}\u{203F}-\u{2040}"
        private_constant :TAG_NAME_FOLLOWING_CODEPOINTS

        # @api private
        # @since 2.1.0
        INVALID_TAG_NAME_FOLLOWING_REGEXP = /[^#{TAG_NAME_FOLLOWING_CODEPOINTS}]/
        private_constant :INVALID_TAG_NAME_FOLLOWING_REGEXP

        # @api private
        # @since 2.1.0
        SAFE_XML_TAG_NAME_REGEXP = /\A[#{TAG_NAME_START_CODEPOINTS}][#{TAG_NAME_FOLLOWING_CODEPOINTS}]*\z/
        private_constant :INVALID_TAG_NAME_FOLLOWING_REGEXP

        # @api private
        # @since 2.1.0
        TAG_NAME_REPLACEMENT_CHAR = "_"
        private_constant :TAG_NAME_REPLACEMENT_CHAR

        # Returns the given string marked as HTML safe, meaning it will not be escaped when included
        # in your view's HTML.
        #
        # This is NOT recommended if the string is coming from untrusted user input. Use at your own
        # peril.
        #
        # @param input [String] the input
        # @return [Hanami::View::HTML::SafeString] the string marked as HTML safe
        #
        # @example
        #   raw(user.name) # => "Little Bobby <alert>Tables</alert>"
        #   raw(user.name).html_safe? # => true
        #
        # @api public
        # @since 2.1.0
        def raw(input)
          input.to_s.html_safe
        end
      end
    end
  end
end
