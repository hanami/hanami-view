# frozen_string_literal: true

require "temple"
require_relative "engine"

module Hanami
  class View
    # Hanami::View ERB template renderer for Tilt.
    #
    # The key features of this ERB implementation are:
    #
    # - Auto-escaping any non-`html_safe?` values given to `<%=` ERB expression tags, with
    #   auto-escaping disabled when using `<%==` tags.
    # - Implicitly capturing and correctly outputting block content without the need for special
    #   helpers. This allows helpers like `<%= form_for(:post) do %>` to be used, with the
    #   `form_for` helper itself doing nothing more special than a `yield`.
    #
    # See [Tilt](https://github.com/jeremyevans/tilt) for rendering options.
    #
    # @example
    #   Hanami::View::ERB::Template.new { "<%= 'Hello, world!' %>" }.render
    #
    # @api private
    # @since 2.1.0
    module ERB
      # ERB Template class
      Template = Temple::Templates::Tilt(Engine)
    end
  end
end
