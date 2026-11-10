# frozen_string_literal: true

module Hanami
  class View
    # Finds the locals a template declares in its magic comment, for Tilt's fixed locals.
    #
    # Tilt's own extraction matches `# locals: (` anywhere in a template, including its text, and
    # takes everything up to the last closing parenthesis on the line. A page showing the syntax as
    # an example then becomes a declaring template, and a comment followed by other parenthesized
    # text fails to compile. Each template engine instead includes a module whose pattern only
    # accepts the declaration as the engine's own comment, and ends it at the parenthesis matching
    # its opening one, skipping any inside quoted strings.
    #
    # Templates including one of these modules extract their declared locals unless given the
    # `extract_fixed_locals` option. Templates from other engines extract them only when given that
    # option, since Tilt's own extraction is not limited to comments.
    #
    # @api private
    class FixedLocals < Module
      # The parenthesized locals, with nested parentheses balanced and quoted strings skipped.
      # Within an ERB comment, neither may run past the comment's closing `%>`.
      ERB_PARAMS = /
        (?<params>\(
          (?:
            "(?:(?!%>)[^"\\]|\\.)*"
            | '(?:(?!%>)[^'\\]|\\.)*'
            | (?!%>)[^()"']
            | \g<params>
          )*
        \))
      /x

      # The parenthesized locals, as for {ERB_PARAMS}, kept to a single line.
      LINE_PARAMS = /
        (?<params>\(
          (?:
            "(?:[^"\\\n]|\\.)*"
            | '(?:[^'\\\n]|\\.)*'
            | [^()"'\n]
            | \g<params>
          )*
        \))
      /x

      # @param pattern [Regexp] matching a declaring comment, capturing its parenthesized locals
      def initialize(pattern)
        super()

        # Overrides `Tilt::Template#set_fixed_locals`, to extract by default.
        define_method(:set_fixed_locals) do
          @options[:extract_fixed_locals] = true unless @options.key?(:extract_fixed_locals)
          super()
        end

        # Overrides `Tilt::Template#extract_fixed_locals`.
        define_method(:extract_fixed_locals) do
          match = pattern.match(@data) if @data.is_a?(String)
          match&.[](:params)
        end

        private :set_fixed_locals, :extract_fixed_locals
      end

      # `<%# locals: (title:) %>`, opening an ERB comment, which may also take a leading trim marker
      # (`<%-#`). The locals may span lines, but not leave the comment's tag.
      ERB = new(/<%-?\#\s*locals:\s*#{ERB_PARAMS}/)

      # `-# locals: (title:)`, a Haml silent comment, indented by any amount.
      HAML = new(/^[ \t]*-\#[ \t]*locals:[ \t]*#{LINE_PARAMS}/)

      # `/# locals: (title:)`, a Slim code comment, indented by any amount.
      SLIM = new(/^[ \t]*\/[ \t]*\#[ \t]*locals:[ \t]*#{LINE_PARAMS}/)
    end
  end
end
