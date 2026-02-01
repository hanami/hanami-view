# frozen_string_literal: true

module Hanami
  class View
    module ERB
      module Filters
        # Implicitly captures and outputs the content inside blocks opened in ERB expression tags,
        # such as `<%= form_for(:post) do %>`.
        #
        # Inspired by Slim's Slim::Controls::Filter#on_slim_output.
        #
        # @since 2.1.0
        # @api private
        class Block < Temple::Filter
          END_LINE_RE = /\bend\b/

          def on_erb_block(escape, code, content)
            tmp = unique_name

            # Remove the last `end` :code sexp, since this is technically "outside" the block
            # contents, which we want to capture separately below. This `end` is added back after
            # capturing the content below.
            case content.last
            in [:code, c] if c =~ END_LINE_RE
              content.pop
            end

            [
              :multi,
              # Capture the result of the code in a variable. We can't do `[:dynamic, code]` because
              # it's probably not a complete expression (which is a requirement for Temple).
              [:code, "#{tmp} = #{code}"],
              # Capture the content of a block in a separate buffer. This means that `yield` will
              # not output the content to the current buffer, but rather return the output.
              [:capture, unique_name, compile(content)],
              [:code, "end"],
              # Output the content.
              [:escape, escape, [:dynamic, tmp]]
            ]
          end
        end
      end
    end
  end
end
