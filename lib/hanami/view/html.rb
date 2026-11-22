# frozen_string_literal: true

module Hanami
  class View
    # HTML-focused behavior for strings intended to be output in templates.
    #
    # @api public
    # @since 2.1.0
    module HTML
      # A string that has been marked as "HTML safe", ensuring that it is not automatically escaped
      # when used in HTML view templates.
      #
      # A SafeString is frozen when initialized to ensure it cannot be mutated after being marked as
      # safe, which could be an avenue for injection of unsafe content.
      #
      # @see String#html_safe
      #
      # @api public
      # @since 2.1.0
      class SafeString < String
        # @api public
        # @since 2.1.0
        def initialize(string)
          super(string)
          freeze
        end

        # @api private
        # @since 2.1.0
        private def initialize_copy(other)
          super
          freeze
        end

        # @return [true]
        #
        # @api public
        # @since 2.1.0
        def html_safe?
          true
        end

        # @return [self]
        #
        # @api public
        # @since 2.1.0
        def html_safe
          self
        end

        # @return [self]
        #
        # @api public
        # @since 2.1.0
        def to_s
          self
        end
      end

      # Provides `String#html_safe`.
      #
      # This module's methods are documented on the core classes they extend.
      #
      # @see String#html_safe
      #
      # @api private
      module StringExtensions
        # @see String#html_safe
        def html_safe
          Hanami::View::HTML::SafeString.new(self)
        end
      end

      # Provides `Object#html_safe?`.
      #
      # This module's methods are documented on the core classes they extend.
      #
      # @see Object#html_safe?
      #
      # @api private
      module ObjectExtensions
        # @see Object#html_safe?
        def html_safe?
          false
        end
      end

      # Provides `Numeric#html_safe?`.
      #
      # This module's methods are documented on the core classes they extend.
      #
      # @see Numeric#html_safe?
      #
      # @api private
      module NumericExtensions
        # @see Numeric#html_safe?
        def html_safe?
          true
        end
      end
    end
  end
end

# Add our methods via included modules, so that Active Support's methods (which it defines directly
# on these classes) take precedence, regardless of load order, and without "method redefined"
# warnings.
#
# Using Active Support's `String#html_safe` when it is loaded is necessary for Hanami View to work
# inside Rails apps, where Rails helpers and other gems expect a mutable
# `ActiveSupport::SafeBuffer`, which escapes unsafe strings appended to it.
String.include Hanami::View::HTML::StringExtensions unless String.method_defined?(:html_safe)
Object.include Hanami::View::HTML::ObjectExtensions
Numeric.include Hanami::View::HTML::NumericExtensions

# @!parse
#   class String
#     # Returns the string as a {Hanami::View::HTML::SafeString}, ensuring the string is not
#     # automatically escaped when used in HTML view templates.
#     #
#     # If Active Support is loaded, its own `String#html_safe` is used instead, which returns an
#     # `ActiveSupport::SafeBuffer`.
#     #
#     # @return [Hanami::View::HTML::SafeString]
#     #
#     # @api public
#     # @since 2.1.0
#     def html_safe; end
#   end
#
#   class Object
#     # @return [false]
#     #
#     # @api public
#     # @since 2.1.0
#     def html_safe?; end
#   end
#
#   class Numeric
#     # @return [true]
#     #
#     # @api public
#     # @since 2.1.0
#     def html_safe?; end
#   end
