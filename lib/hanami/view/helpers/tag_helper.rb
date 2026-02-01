# frozen_string_literal: true

# Based on ActionView::Helpers::TagHelper, also released under the MIT licence.
#
# Copyright (c) David Heinemeier Hansson

module Hanami
  class View
    module Helpers
      # Helper methods for generating HTML tags.
      #
      # When using full Hanami apps, these helpers will be automatically available in your view
      # templates, part classes and scope classes.
      #
      # When using hanami-view standalone, include this module directly in your base part and scope
      # classes, or in specific classes as required.
      #
      # @example Standalone usage
      #   class BasePart < Hanami::View::Part
      #     include Hanami::View::Helpers::TagHelper
      #   end
      #
      #   class BaseScope < Hanami::View::Scope
      #     include Hanami::View::Helpers::TagHelper
      #   end
      #
      #   class BaseView < Hanami::View
      #     config.part_class = BasePart
      #     config.scope_class = BaseScope
      #   end
      #
      # @api public
      # @since 2.1.0
      module TagHelper
        module_function

        # Returns a tag builder for building HTML tag strings.
        #
        # @example General usage
        #   tag.div # => <div></div>
        #   tag.img # => <img>
        #
        #   tag.div("hello")        # => <div>hello</div>
        #   tag.div { "hello" }     # => <div>hello</div>
        #   tag.div(tag.p("hello")) # => <div><p>hello</p></div>
        #
        #   tag.div(class: ["a", "b"])              # => <div class="a b"></div>
        #   tag.div(class: {"a": true, "b": false}) # => <div class="a"></div>
        #
        #   tag.div(id: "el", data: {x: "y"}) # => <div id="el" data-x="y"></div>
        #   tag.div(id: "el", aria: {x: "y"}) # => <div id="el" aria-x="y"></div>
        #
        #   tag.custom_tag("hello") # => <custom-tag>hello</custom-tag>
        #
        # @example Escaping
        #   tag.p("<script>alert()</script>")         # => <p>&lt;script&gt;alert()&lt;/script&gt;</p>
        #   tag.p(class: "<script>alert()</script>")  # => <p class="&lt;script&gt;alert()&lt;/script&gt;"></p>
        #   tag.p("<em>safe content</em>".html_safe)  # => <p><em>safe content</em></p>
        #
        # @example Within templates
        #   <%= tag.div(id: "el") do %>
        #     <p>Template content can be mixed in.</p>
        #     <%= tag.p("Also nested tag builders.") %>
        #   <% end %>
        #
        # @api public
        # @since 2.1.0
        def tag
          tag_builder
        end

        # Returns an anchor tag for the given contents and URL.
        #
        # The tag's contents are automatically escaped (unless marked as HTML safe).
        #
        # Uses the {#tag} builder to prepare the tag, so all tag builder options are also used.
        #
        # @overload link_to(content, url, **attributes)
        #   Returns a tag using a given string as the contents.
        #
        #   @param content [String] content used in the a tag
        #   @param url [String] URL to be used in the `href` attribute
        #   @param attributes [Hash] HTML attributes to include in the tag
        #
        # @overload link_to(url, **attributes, &block)
        #   Returns a tag using the given block's return value as the contents.
        #
        #   @param url [String] URL to be used in the `href` attribute
        #   @param attributes [Hash] HTML attributes to include in the tag
        #   @param block [Proc] block that returns the contents of the tag
        #
        # @return [String] HTML markup for the anchor tag
        #
        # @example
        #   link_to("Home", "/")
        #   # => <a href="/">Home</a>
        #
        #   link_to("/") { "Home" }
        #   # => <a href="/">Home</a>
        #
        #   link_to("Home", "/", class: "button") %>
        #   # => <a href="/" class="button">Home</a>
        #
        # @example Escaping
        #   link_to("<script>alert('xss')</script>", "/")
        #   # => <a href="/">&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</a>
        #
        #   link_to("/") { "<script>alert('xss')</script>" }
        #   # => <a href="/">&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</a>
        #
        # @see #tag
        #
        # @api public
        # @since 2.1.0
        def link_to(content, url = nil, **attributes, &block)
          if block
            raise ArgumentError if url && content

            url = content
            content = nil
          end

          attributes[:href] = url or raise ArgumentError

          tag.a(content, **attributes, &block)
        end

        # Returns a string of space-separated tokens from a range of given arguments.
        #
        # This is intended for building an HTML tag attribute value, such as a list of class names.
        #
        # @return [String]
        #
        # @example
        #   token_list("foo", "bar")
        #   # => "foo bar"
        #
        #   token_list("foo", "foo bar")
        #   # => "foo bar"
        #
        #   token_list({ foo: true, bar: false })
        #   # => "foo"
        #
        #   token_list(nil, false, 123, "", "foo", { bar: true })
        #   # => "123 foo bar"
        #
        # @api public
        # @since 2.1.0
        def token_list(*args)
          tokens = build_tag_values(*args).flat_map { |value|
            safe = value.html_safe?
            value.split(/\s+/).map { |s| safe ? s.html_safe : s }
          }

          EscapeHelper.escape_join(tokens, " ")
        end

        # @see #token_list
        #
        # @api public
        # @since 2.1.0
        def class_names(...)
          token_list(...)
        end

        # @api private
        # @since 2.1.0
        def build_tag_values(*args)
          tag_values = []

          args.each do |tag_value|
            case tag_value
            when Hash
              tag_value.each do |key, val|
                tag_values << key.to_s if val && !key.to_s.empty?
              end
            when Array
              tag_values.concat build_tag_values(*tag_value)
            else
              tag_values << tag_value.to_s unless tag_value.to_s.empty?
            end
          end

          tag_values
        end

        # @api private
        # @since 2.1.0
        def tag_builder
          @tag_builder ||= TagBuilder.new(inflector: tag_builder_inflector)
        end

        # @api private
        # @since 2.1.0
        def tag_builder_inflector
          if respond_to?(:_context)
            return _context.inflector
          end

          # TODO: When hanami-view moves to Zeitwerk (and the only external require is for
          # "dry/view"), remove this.
          require "dry/inflector"
          Dry::Inflector.new
        end
      end
    end
  end
end
