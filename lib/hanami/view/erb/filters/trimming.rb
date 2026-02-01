# frozen_string_literal: true

# Based on Temple::ERB::Trimming, also released under the MIT licence.
#
# Copyright (c) 2010-2023 Magnus Holm.

module Hanami
  class View
    module ERB
      module Filters
        # Trims spurious spaces from ERB-generated text.
        #
        # Deletes spaces around "<% %>" and leave spaces around "<%= %>".
        #
        # This is a copy of Temple::ERB::Trimming, with the one difference being that it descends
        # into the sexp-tree by running `compile(e)` for any non-`:static` sexps. This is necessary
        # for our implementation of ERB, because we capture block content by creating additional
        # `:multi` sexps with their own nested content.
        #
        # @api private
        # @since 2.1.0
        class Trimming < Temple::Filter
          define_options trim: true

          # rubocop:disable Metrics/PerceivedComplexity

          def on_multi(*exps)
            if options[:trim]
              exps = exps.each_with_index.map do |e, i|
                if e.first == :static && i > 0 && exps[i - 1].first == :code
                  [:static, e.last.lstrip]
                elsif e.first == :static && i < exps.size - 1 && exps[i + 1].first == :code
                  [:static, e.last.rstrip]
                else
                  compile(e)
                end
              end
            end

            [:multi, *exps]
          end

          # rubocop:enable Metrics/PerceivedComplexity
        end
      end
    end
  end
end
