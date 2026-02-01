# frozen_string_literal: true

module Hanami
  class View
    module Helpers
      # Helper methods for formatting numbers as text.
      #
      # When using full Hanami apps, these helpers will be automatically available in your view
      # templates, part classes and scope classes.
      #
      # When using hanami-view standalone, include this module directly in your base part and scope
      # classes, or in specific classes as required.
      #
      # @example Standalone usage
      #   class BasePart < Hanami::View::Part
      #     include Hanami::View::Helpers::NumberFormattingHelper
      #   end
      #
      #   class BaseScope < Hanami::View::Scope
      #     include Hanami::View::Helpers::NumberFormattingHelper
      #   end
      #
      #   class BaseView < Hanami::View
      #     config.part_class = BasePart
      #     config.scope_class = BaseScope
      #   end
      #
      # @api public
      # @since 2.1.0
      module NumberFormattingHelper
        module_function

        # Default delimiter
        #
        # @return [String] default delimiter
        #
        # @since 2.1.0
        # @api private
        DEFAULT_DELIMITER = ","
        private_constant :DEFAULT_DELIMITER

        # Default separator
        #
        # @return [String] default separator
        #
        # @since 2.1.0
        # @api private
        DEFAULT_SEPARATOR = "."
        private_constant :DEFAULT_SEPARATOR

        # Default precision
        #
        # @return [Integer] default rounding precision
        #
        # @since 2.1.0
        # @api private
        DEFAULT_PRECISION = 2
        private_constant :DEFAULT_PRECISION

        # Returns a formatted string for the given number.
        #
        # Accepts a number (`Numeric`) or a string representation of a number.
        #
        # If an integer is given, applies no precision in the returned string. For all other kinds
        # (`Float`, `BigDecimal`, etc.), formats the number as a float.
        #
        # Raises an `ArgumentError` if the argument cannot be coerced into a number for formatting.
        #
        # @param number [Numeric, String] the number to be formatted
        # @param delimiter [String] hundred delimiter
        # @param separator [String] fractional part separator
        # @param precision [String] rounding precision
        #
        # @return [String] formatted number
        #
        # @raise [ArgumentError] if the number can't be formatted
        #
        # @example
        #   format_number(1_000_000) # => "1,000,000"
        #   format_number(Math::PI) # => "3.14"
        #   format_number(Math::PI, precision: 4) # => "3.1416"
        #   format_number(1256.95, delimiter: ".", separator: ",") # => "1.256,95"
        #
        # @api public
        # @since 2.1.0
        def format_number(number, delimiter: DEFAULT_DELIMITER, separator: DEFAULT_SEPARATOR, precision: DEFAULT_PRECISION) # rubocop:disable Layout/LineLength
          Formatter.call(number, delimiter: delimiter, separator: separator, precision: precision)
        end

        # Formatter
        #
        # @since 2.1.0
        # @api private
        class Formatter
          # Regex to delimit the integer part of a number into groups of three digits.
          #
          # @since 2.1.0
          # @api private
          DELIMITING_REGEX = /(\d)(?=(\d{3})+$)/
          private_constant :DELIMITING_REGEX

          # Regex to guess if the number is a integer.
          #
          # @since 2.1.0
          # @api private
          INTEGER_REGEXP = /\A\d+\z/
          private_constant :INTEGER_REGEXP

          # @see NumberFormattingHelper#format_number
          #
          # @since 2.1.0
          # @api private
          def self.call(number, delimiter:, separator:, precision:)
            number = coerce(number)
            str = to_str(number, precision)
            array = parts(str, delimiter)

            array.join(separator)
          end

          # Coerces the given number or string into a number.
          #
          # @since 2.1.0
          # @api private
          def self.coerce(number)
            case number
            when NilClass
              raise ArgumentError, "failed to convert #{number.inspect} to number"
            when ->(n) { n.to_s.match(INTEGER_REGEXP) }
              Integer(number)
            else
              begin
                Float(number)
              rescue TypeError
                raise ArgumentError, "failed to convert #{number.inspect} to float"
              rescue ArgumentError => exception
                raise exception.class, "failed to convert #{number.inspect} to float"
              end
            end
          end

          # Formats the given number as a string.
          #
          # @since 2.1.0
          # @api private
          def self.to_str(number, precision)
            case number
            when Integer
              number.to_s
            else
              ::Kernel.format("%.#{precision}f", number)
            end
          end

          # Returns the integer and fractional parts of the given number string.
          #
          # @since 2.1.0
          # @api private
          def self.parts(string, delimiter)
            integer_part, fractional_part = string.split(DEFAULT_SEPARATOR)
            [delimit_integer(integer_part, delimiter), fractional_part].compact
          end

          # Delimits the given integer part of a number.
          #
          # @param integer_part [String] integer part of the number
          # @param delimiter [String] hundreds delimiter
          #
          # @return [String] delimited integer string
          #
          # @since 2.1.0
          # @api private
          def self.delimit_integer(integer_part, delimiter)
            integer_part.gsub(DELIMITING_REGEX) { |digit| "#{digit}#{delimiter}" }
          end
        end
      end
    end
  end
end
