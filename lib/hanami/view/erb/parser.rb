# frozen_string_literal: true

# Hanami::View::ERB is based on Temple::ERB::Parser, also released under the MIT licence.
#
# Copyright (c) 2010-2023 Magnus Holm.

require "temple"

module Hanami
  class View
    module ERB
      # ERB parser for Hanami views.
      #
      # This is a [Temple][temple] parser that prepares a Temple [s-expression][expression] (sexp)
      # for later generating as HTML via {ERB::Engine}.
      #
      # [temple]: https://github.com/judofyr/temple
      # [expressions]: https://github.com/judofyr/temple/blob/master/EXPRESSIONS.md
      #
      # The key features of this parser are:
      #
      # - Auto-escaping any non-`html_safe?` values given to `<%=` ERB expression tags, with
      #   auto-escaping disabled when using `<%==` tags.
      # - Implicitly capturing and correctly outputting block content without the need for special
      #   helpers. This allows helpers like `<%= form_for(:post) do %>` to be used, with the
      #   `form_for` helper itself doing nothing more special than a `yield`.
      #
      # To support implicit block capture, this parser differs somewhat from Temple's example ERB
      # parser, as well as most other Temple parsers. Typical parsers prepare a single `result` sexp
      # up front, like so:
      #
      #   result = [:multi]
      #
      # As parsing occurs, new Temple sexps are then pushed onto this `result`.
      #
      # In this parser, however, we prepare a _stack_ of results:
      #
      #   results = [[:multi]]
      #
      # The first item in the stack (`[:multi]`) is the final result that will be returned at the
      # end of parsing. Every sexp that is generated during parsing will still be added to this
      # result, directly or indirectly.
      #
      # How this happens is that during parsing, every new sexp is push to the _last_ result in this
      # stack, representing the "current" result.
      #
      # The nature of stack becomes important when we encounter an ERB expression tag that opens a
      # code block, such as `<%= form_for(:post) do %>`.
      #
      # In this case, we push an `[:erb, :block, ..., [:multi]]` sexp to the last result, with its
      # `[:multi]` representing the _contents_ of that code block. We then also push this particular
      # `[:multi]` onto the `results` stack, so that any subsequent sexps are added to the block's
      # own contents.
      #
      # Then, when we encounter the `<% end %>` closing tag for that block, we pop the block's
      # `[:multi]` off the results stack. This `[:multi]` isn't lost, however, because it is still
      # referenced inside the `[:erb, :block, ..., [:multi]]` sexp.
      #
      # Taking this approach (along with the `on_erb_block` sexp-handling code in
      # `Hanami::View::ERB::Filters::Block`) allows us to implicitly capture the contents of the
      # block and output it in place. This means that helpers that expect blocks do not need to
      # explicitly call a `capture` helper (or similar) internally. Instead they can just `yield`,
      # per idiomatic Ruby.
      #
      # In fact, we pop a result off the stack _every_ time we encounter an `<% end %>` tag. To
      # acount for this, every time we encounter an ERB code tag that will have a matching closing
      # tag (such as `<% if some_cond %>` or `<% 5.times do %>`), we push another reference to the
      # _current_ last result onto the `results` stack. This allows subsequent sexps to be added to
      # the same item on the stack (they need no special handling; the special handling is for
      # blocks with ERB expression tags only) while still allowing it to be popped again when the
      # matching `<% end %>` is encountered.
      #
      # In this way, this stack of results will grow every time a new scope requiring an `end` is
      # opened, and then will shrink again as each `end` is encountered; think of it as matching the
      # level of LHS indentation if you were writing such code by hand. This allows each new
      # generated sexp to be pushed onto `results.last`, knowing that it will go into the right
      # place in the overall sexp tree. By the time we finish parsing, just a single result will
      # remain, which is the value returned.
      #
      # @api private
      # @since 2.1.0
      class Parser < Temple::Parser
        ERB_PATTERN = /(\n|<%%|%%>)|<%(==?|\#)?(.*?)?-?%>/m

        IF_UNLESS_CASE_LINE_RE = /\A\s*(if|unless|case)\b/
        BLOCK_LINE_RE = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/
        END_LINE_RE = /\bend\b/

        # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity

        def call(input)
          results = [[:multi]]
          pos = 0

          input.scan(ERB_PATTERN) do |token, indicator, code|
            # Capture any text between the last ERB tag and the current one, and update the position
            # to match the end of the current tag for the next iteration of text collection.
            text = input[pos...$~.begin(0)]
            pos  = $~.end(0)

            if token
              # First, handle certain static tokens picked up by our ERB_PATTERN regexp. These are
              # newlines as well as the special codes for literal `<%` and `%>` values.
              case token
              when "\n"
                results.last << [:static, "#{text}\n"] << [:newline]
              when "<%%", "%%>"
                results.last << [:static, text] unless text.empty?
                token.slice!(1)
                results.last << [:static, token]
              end
            else
              # Next, handle actual ERB tags. Start by adding any static text between this match and
              # the last.
              results.last << [:static, text] unless text.empty?

              case indicator
              when "#"
                # Comment tags: <%# this is a comment %>
                results.last << [:code, "\n" * code.count("\n")]
              when %r{=}
                # Expression tags: <%= "hello (auto-escaped)" %> or <%== "hello (not escaped)" %>
                if code =~ BLOCK_LINE_RE
                  # See Hanami::View::Erb::Filters::Block for the processing of `:erb, :block` sexps
                  block_node = [:erb, :block, indicator.size == 1, code, (block_content = [:multi])]
                  results.last << block_node

                  # For blocks opened in ERB expression tags, push this `[:multi]` sexp
                  # (representing the content of the block) onto the stack of resuts. This allows
                  # subsequent results to be appropriately added inside the block, until its closing
                  # tag is encountered, and this `block_content` multi is subsequently popped off
                  # the results stack.
                  results << block_content
                else
                  results.last << [:escape, indicator.size == 1, [:dynamic, code]]
                end
              else
                # Code tags: <% if some_cond %>
                if code =~ BLOCK_LINE_RE || code =~ IF_UNLESS_CASE_LINE_RE
                  results.last << [:code, code]

                  # For ERB code tags that will result in a matching `end`, push the last result
                  # back onto the stack of results. This might seem redundant, but it allows
                  # subsequent sexps to continue to be pushed onto the same result while also
                  # allowing it to be safely popped again when the matching `end` is encountered.
                  results << results.last
                elsif code =~ END_LINE_RE
                  results.last << [:code, code]
                  results.pop
                else
                  results.last << [:code, code]
                end
              end
            end
          end

          # Add any text after the final ERB tag
          results.last << [:static, input[pos..]]
        end

        # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity
      end
    end
  end
end
