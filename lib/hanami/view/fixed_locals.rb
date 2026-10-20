# frozen_string_literal: true

module Hanami
  class View
    # Finds the locals a template declares in its magic comment, for Tilt's fixed locals.
    #
    # Tilt's own extraction matches `# locals: (` anywhere in a template, including its text, and
    # takes everything up to the last closing parenthesis on the line. A page showing the syntax as
    # an example then becomes a declaring template, and a comment followed by other parenthesised
    # text fails to compile. Each template engine instead includes a module whose pattern only
    # accepts the declaration at the start of a comment, and ends it at the parenthesis matching
    # its opening one.
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

      # `<%# locals: (title:) %>`, opening an ERB comment. The locals may span lines, but not leave
      # the comment's tag.
      #
      # @api private
      # @since 3.1.0
      ERB = new(/<%\#\s*locals:\s*(?<params>\((?:(?!%>)[^()]|\g<params>)*\))/)

      # `-# locals: (title:)` in Haml, or `/# locals: (title:)` in Slim, with only non-word
      # characters before it on its line.
      #
      # @api private
      # @since 3.1.0
      LINE = new(/^[^\w\n]*\#\s*locals:\s*(?<params>\((?:[^()\n]|\g<params>)*\))/)
    end
  end
end
