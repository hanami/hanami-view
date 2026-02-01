# frozen_string_literal: true

require "json"

module Hanami
  class View
    module Helpers
      module TagHelper
        # Tag builder returned from {TagHelper#tag}.
        #
        # @see TagHelper#tag
        #
        # @api public
        # @since 2.1.0
        class TagBuilder
          # @api private
          # @since 2.1.0
          HTML_VOID_ELEMENTS = %i[
            area base br col embed hr img input keygen link meta param source track wbr
          ].to_set

          # @api private
          # @since 2.1.0
          SVG_SELF_CLOSING_ELEMENTS = %i[
            animate animateMotion animateTransform circle ellipse line path polygon polyline rect set stop use view
          ].to_set

          # @api private
          # @since 2.1.0
          ATTRIBUTE_SEPARATOR = " "

          # @api private
          # @since 2.1.0
          BOOLEAN_ATTRIBUTES = %w[
            allowfullscreen allowpaymentrequest async autofocus
            autoplay checked compact controls declare default
            defaultchecked defaultmuted defaultselected defer
            disabled enabled formnovalidate hidden indeterminate
            inert ismap itemscope loop multiple muted nohref
            nomodule noresize noshade novalidate nowrap open
            pauseonexit playsinline readonly required reversed
            scoped seamless selected sortable truespeed
            typemustmatch visible
          ].to_set
          BOOLEAN_ATTRIBUTES.merge(BOOLEAN_ATTRIBUTES.map(&:to_sym))
          BOOLEAN_ATTRIBUTES.freeze

          # @api private
          # @since 2.1.0
          ARIA_PREFIXES = ["aria", :aria].to_set.freeze

          # @api private
          # @since 2.1.0
          DATA_PREFIXES = ["data", :data].to_set.freeze

          # @api private
          # @since 2.1.0
          TAG_TYPES = {}.tap do |hsh|
            BOOLEAN_ATTRIBUTES.each { |attr| hsh[attr] = :boolean }
            DATA_PREFIXES.each { |attr| hsh[attr] = :data }
            ARIA_PREFIXES.each { |attr| hsh[attr] = :aria }
            hsh.freeze
          end

          # @api private
          # @since 2.1.0
          PRE_CONTENT_STRINGS = Hash.new { "" }
          PRE_CONTENT_STRINGS[:textarea]  = "\n"
          PRE_CONTENT_STRINGS["textarea"] = "\n"
          PRE_CONTENT_STRINGS.freeze

          # @api private
          # @since 2.1.0
          attr_reader :inflector

          # @api private
          # @since 2.1.0
          def initialize(inflector:)
            @inflector = inflector
          end

          # Transforms a Hash into HTML Attributes, ready to be interpolated into
          # ERB.
          #
          # @example
          #   <input <%= tag.attributes(type: :text, aria: { label: "Search" }) %> >
          #   # => <input type="text" aria-label="Search">
          #
          # @api public
          # @since 2.1.0
          def attributes(**attributes)
            tag_options(**attributes).to_s.strip.html_safe
          end

          # Returns a `<p>` HTML tag.
          #
          # @api public
          # @since 2.1.0
          def p(*args, **options, &block)
            tag_string(:p, *args, **options, &block)
          end

          # @api private
          # @since 2.1.0
          def tag_string(name, content = nil, **options)
            content = yield if block_given?
            self_closing = SVG_SELF_CLOSING_ELEMENTS.include?(name)

            if (HTML_VOID_ELEMENTS.include?(name) || self_closing) && content.nil?
              "<#{inflector.dasherize(name.to_s)}#{tag_options(**options)}#{self_closing ? " />" : ">"}".html_safe
            else
              content_tag_string(inflector.dasherize(name.to_s), content || "", **options)
            end
          end

          # @api private
          # @since 2.1.0
          def content_tag_string(name, content, **options)
            tag_options = tag_options(**options) unless options.empty?

            name = EscapeHelper.escape_xml_name(name)
            content = EscapeHelper.escape_html(content)

            "<#{name}#{tag_options}>#{PRE_CONTENT_STRINGS[name]}#{content}</#{name}>".html_safe
          end

          # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

          # @api private
          # @since 2.1.0
          def tag_options(**options)
            return if options.none?

            output = +""

            options.each_pair do |key, value|
              type = TAG_TYPES[key]

              if type == :data && value.is_a?(Hash)
                value.each_pair do |k, v|
                  next if v.nil?

                  output << ATTRIBUTE_SEPARATOR
                  output << prefix_tag_option(key, k, v)
                end
              elsif type == :aria && value.is_a?(Hash)
                value.each_pair do |k, v|
                  next if v.nil?

                  case v
                  when Array, Hash
                    tokens = TagHelper.build_tag_values(v)
                    next if tokens.none?

                    v = EscapeHelper.escape_join(tokens, " ")
                  else
                    v = v.to_s
                  end

                  output << ATTRIBUTE_SEPARATOR
                  output << prefix_tag_option(key, k, v)
                end
              elsif type == :boolean
                if value
                  output << ATTRIBUTE_SEPARATOR
                  output << boolean_tag_option(key)
                end
              elsif !value.nil?
                output << ATTRIBUTE_SEPARATOR
                output << tag_option(key, value)
              end
            end

            output unless output.empty?
          end

          # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

          # @api private
          # @since 2.1.0
          def boolean_tag_option(key)
            %(#{key}="#{key}")
          end

          # @api private
          # @since 2.1.0
          def tag_option(key, value)
            key = EscapeHelper.escape_xml_name(key)

            case value
            when Array, Hash
              value = TagHelper.build_tag_values(value) if key.to_s == "class"
              value = EscapeHelper.escape_join(value, " ")
            when Regexp
              value = EscapeHelper.escape_html(value.source)
            else
              value = EscapeHelper.escape_html(value)
            end
            value = value.gsub('"', "&quot;") if value.include?('"')

            %(#{key}="#{value}")
          end

          private

          # @api private
          # @since 2.1.0
          def method_missing(called, *args, **options, &block)
            tag_string(called, *args, **options, &block)
          end

          # @api private
          # @since 2.1.0
          def respond_to_missing?(*args)
            true
          end

          # @api private
          # @since 2.1.0
          def prefix_tag_option(prefix, key, value)
            key = "#{prefix}-#{inflector.dasherize(key.to_s)}"

            unless value.is_a?(String) || value.is_a?(Symbol)
              value = value.to_json
            end

            tag_option(key, value)
          end
        end
      end
    end
  end
end
