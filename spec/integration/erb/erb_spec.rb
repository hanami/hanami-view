# frozen_string_literal: true

require "tilt/erubi"

RSpec.describe Hanami::View::ERB::Template do
  def render(src, *render_args, template_opts: {}, **render_opts)
    Hanami::View::ERB::Template.new(**template_opts) { src }
      .render(*render_args, **render_opts)
  end

  def render_erubi(src, *render_args, template_opts: {}, **render_opts)
    Tilt::ErubiTemplate.new(**template_opts) { src }
      .render(*render_args, **render_opts)
  end

  it "compiles ERB" do
    src = <<~ERB
      %% hi
      = hello
      <% 3.times do |n| %>
      * <%= n %>
      <% end %>
    ERB

    output = render(src)

    expect(output).to eq <<~TEXT
      %% hi
      = hello
      * 0
      * 1
      * 2
    TEXT

    expect(output).to eq render_erubi(src)
  end

  it "supports trim mode" do
    src = <<~ERB
      %% hi
      = hello
      <% 3.times do |n| %>
      * <%= n %>
      <% end %>
    ERB

    trimmed_output = render(src, template_opts: {trim: true})

    expect(trimmed_output).to eq <<~TEXT
      %% hi
      = hello
      * 0
      * 1
      * 2
    TEXT

    expect(trimmed_output).to eq(render_erubi(src, template_opts: {trim: true}))

    non_trimmed_output = render(src, template_opts: {trim: false})

    expect(non_trimmed_output).to eq <<~TEXT
      %% hi
      = hello

      * 0

      * 1

      * 2

    TEXT

    expect(non_trimmed_output).to eq(render_erubi(src, template_opts: {trim: false}))
  end

  it "respects comments" do
    src = <<~ERB
      hello
        <%# comment -- ignored -- useful in testing %>
      world
    ERB

    output = render(src)

    expect(output).to eq <<~TEXT
      hello
      world
    TEXT

    expect(output).to eq render_erubi(src)
  end

  it "respects <%% and %%>" do
    src = <<~ERB
      <%%
      <% if true %>
        %%>
      <% end %>
    ERB

    output = render(src)

    expect(output).to eq <<~TEXT
      <%
        %>
    TEXT

    # No erubi check since it doesn't support these tokens
  end

  it "escapes strings automatically in expression tags" do
    src = "<%= '<' %>"
    expect(render(src)).to eq "&lt;"
  end

  it "does not escape HTML safe strings in expression tags" do
    src = "<%= '<'.html_safe %>"
    expect(render(src)).to eq "<"
  end

  it "does not escape strings within '==' expression tags" do
    src = "<%== '<' %>"
    expect(render(src)).to eq "<"
  end

  it "captures content within blocks in expression tags" do
    scope = Class.new do
      def wrapped
        %(<div class="wrapped">#{yield}</div>).html_safe
      end
    end.new

    src = <<~ERB
      <%= wrapped do %>
        <span>hi there</span>
      <% end %>
    ERB

    output = render(src, scope)

    expect(output).to eq <<~HTML
      <div class="wrapped">
        <span>hi there</span>
      </div>
    HTML
  end

  it "captures content within nested blocks in expression tags" do
    scope = Class.new do
      def wrapped
        %(<div class="wrapped">#{yield}</div>).html_safe
      end
    end.new

    src = <<~ERB
      <%= wrapped do %>
        <%= wrapped do %>
          <span>hi there</span>
        <% end %>
      <% end %>
    ERB

    output = render(src, scope)

    expect(output).to eq <<~HTML
      <div class="wrapped">
        <div class="wrapped">
          <span>hi there</span>
        </div>
      </div>
    HTML
  end

  it "captures content within blocks in expression tags, mixed with nested flow control code" do
    scope = Class.new do
      def wrapped
        %(<div class="wrapped">#{yield}</div>).html_safe
      end
    end.new

    src = <<~ERB
      <%= wrapped do %>
        <% if true %>
          <span>hi there</span>
          <% if false %>
            <span>bye bye</span>
          <% end %>
        <% end %>
      <% end %>
    ERB

    output = render(src, scope)

    expect(output).to eq <<~HTML
      <div class="wrapped">
          <span>hi there</span>
      </div>
    HTML
  end

  it "marks captured block content as HTML safe" do
    scope = Class.new {
      def html_safe_capture
        yield.html_safe?
      end
    }.new

    src = <<~ERB
      <%= html_safe_capture do %>
        <div>Some content</div>
        <div>goes here.</div>
      <% end %>
    ERB

    output = render(src, scope)

    expect(output.strip).to eq "true"
  end

  it "marks nested captured blocks as HTML safe" do
    scope = Class.new {
      def html_safe_capture
        captured = yield
        safe = captured.html_safe?

        "#{safe}: #{captured.strip}".then { |str| safe ? str.html_safe : str }
      end
    }.new

    src = <<~ERB
      <%= html_safe_capture do %>
        <div>Some content here.</div>
        <%= html_safe_capture do %>
          <div>Nested content here.</div>
        <% end %>
      <% end %>
    ERB

    output = render(src, scope)

    expect(output.strip).to eq <<~TEXT.strip
      true: <div>Some content here.</div>
        true: <div>Nested content here.</div>
    TEXT
  end

  it "supports case expressions" do
    # Case expressions need this unconventional opening tag to work in ERB; see this 2009 gist for
    # more: https://gist.github.com/davidphasson/91613
    src = <<~ERB
      <% case "hello"
        when "hello" %>
          Hello
        <% when "goodbye" %>
          Goodbye
      <% end %>
    ERB

    output = render(src)

    expect(output).to eq "    Hello\n"

    expect(output).to eq render_erubi(src)
  end
end
