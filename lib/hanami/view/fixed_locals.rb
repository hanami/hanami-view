# frozen_string_literal: true

module Hanami
  class View
    # Finds the locals a template declares in its magic comment, for Tilt's fixed locals.
    #
    # Tilt's own extraction matches `# locals: (` anywhere in a template, including its text, and
    # takes everything up to the last closing parenthesis on the line. A page showing the syntax as
    # an example then becomes a declaring template, and a comment followed by other parenthesised
    # text fails to compile. Each template engine instead includes a module that only accepts the
    # declaration as the whole of one of that language's comments.
    #
    # @api private
    # @since 3.1.0
    class FixedLocals < Module
      # @param pattern [Regexp] matching a declaring comment, capturing its parenthesised locals
      #
      # @api private
      # @since 3.1.0
      def initialize(pattern)
        super()

        # Overrides `Tilt::Template#extract_fixed_locals`.
        define_method(:extract_fixed_locals) do
          match = pattern.match(@data) if @data.is_a?(String)
          match&.[](1)
        end
      end

      # `<%# locals: (title:) %>`, which may span several lines but not leave its tag.
      #
      # @api private
      # @since 3.1.0
      ERB = new(/<%#\s*locals:\s*(\((?:(?!%>).)*\))\s*-?%>/m)

      # `-# locals: (title:)`, on a line of its own.
      #
      # @api private
      # @since 3.1.0
      HAML = new(/^[ \t]*-#[ \t]*locals:[ \t]*(\(.*\))[ \t]*$/)

      # `/# locals: (title:)` or `//# locals: (title:)`, on a line of its own.
      #
      # @api private
      # @since 3.1.0
      SLIM = new(%r{^[ \t]*/{1,2}[ \t]*\#[ \t]*locals:[ \t]*(\(.*\))[ \t]*$})
    end
  end
end
