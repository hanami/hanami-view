# frozen_string_literal: true

RSpec.describe "View / lazy exposures" do
  let(:base_view) {
    dir = self.dir

    Class.new(Hanami::View) {
      config.paths = dir.join("templates")
      config.template = "page"
    }
  }

  let(:calls) { [] }
  let(:dir) { make_tmp_directory }

  # Returns a view that renders the given template (and layout, if given) source.
  def build_view(template:, layout: nil, &block)
    write_template("page.html.erb", template)
    write_template("layouts/app.html.erb", layout) if layout

    calls = self.calls

    Class.new(base_view) {
      config.layout = "app" if layout

      # An instrument for tracking when exposures are called
      define_method(:calls) { calls }

      class_eval(&block)
    }.new
  end

  def write_template(path, source)
    dir.join("templates", path).tap { |file| file.dirname.mkpath }.write(source)
  end

  it "calls an exposure only when a template reads it" do
    template = <<~ERB
      <% mark_start.call %><p><%= body %></p>
    ERB
    view = build_view(template:) {
      expose(:mark_start) { -> { calls << :template_start } }
      expose(:body) { calls << :body; "Body" }
      expose(:unused) { calls << :unused; "Unused" }
    }

    expect(view.call.to_s).to eq "<p>Body</p>\n"
    expect(calls).to eq [:template_start, :body]
  end

  it "calls an exposure only once, even when both the template and another exposure read it" do
    template = <<~ERB
      <p><%= title %></p><p><%= body %></p>
    ERB
    view = build_view(template:) {
      expose(:title) { calls << :title; "Title" }
      expose(:body) { |title| calls << :body; "Body for #{title}" }
    }

    expect(view.call.to_s).to eq "<p>Title</p><p>Body for Title</p>\n"
    expect(calls).to eq [:title, :body]
  end

  it "calls exposures again for each render" do
    template = <<~ERB
      <p><%= body %></p>
    ERB
    view = build_view(template:) {
      expose(:body) { calls << :body; "Body" }
    }

    view.call
    view.call

    expect(calls).to eq [:body, :body]
  end

  describe "layouts" do
    it "shares resolved values between the page and the layout" do
      layout = <<~ERB
        <title><%= title %></title><%= yield %>
      ERB
      template = <<~ERB
        <p><%= title %></p>
      ERB
      view = build_view(layout:, template:) {
        expose(:title, layout: true) { calls << :title; "Title" }
      }

      expect(view.call.to_s).to eq "<title>Title</title><p>Title</p>\n\n"
      expect(calls).to eq [:title]
    end

    it "gives the layout only the exposures marked with `layout: true`" do
      layout = <<~ERB
        <%= locals.key?(:title) %> <%= locals.key?(:body) %> <%= yield %>
      ERB
      template = <<~ERB
        <p><%= body %></p>
      ERB
      view = build_view(layout:, template:) {
        expose(:title, layout: true) { "Title" }
        expose(:body) { "Body" }
      }

      expect(view.call.to_s).to eq "true false <p>Body</p>\n\n"
    end
  end

  describe "eager exposures" do
    it "calls every form of eager exposure before rendering, even when no template reads them" do
      template = <<~ERB
        <% mark_start.call %>
      ERB
      view = build_view(template:) {
        expose(:mark_start) { -> { calls << :template_start } }
        expose!(:body) { calls << :body; "Body" }
        expose(:option, eager: true) { calls << :option; "Option" }
        private_expose(:hidden, eager: true) { calls << :hidden; "Hidden" }
        decorate!(:decorated) { calls << :decorated; "Decorated" }
      }

      rendered = view.call

      expect(calls).to eq [:body, :option, :hidden, :decorated, :template_start]
      expect(rendered[:decorated]).to be_a Hanami::View::Part
      expect(rendered.locals).not_to include(:hidden)
    end

    it "calls the dependencies of eager exposures eagerly" do
      template = <<~ERB
        <% mark_start.call %><p><%= body %></p>
      ERB
      view = build_view(template:) {
        expose(:mark_start) { -> { calls << :template_start } }
        expose(:a) { calls << :a; "a" }
        private_expose(:b) { |a| calls << :b; "#{a}b" }
        expose!(:c) { |b| calls << :c; "#{b}c" }
        expose(:body) { calls << :body; "Body" }
      }

      rendered = view.call

      expect(calls).to eq [:a, :b, :c, :template_start, :body]
      expect(rendered[:c]).to eq "abc"
    end

    it "raises errors from eager exposures before any template renders" do
      template = <<~ERB
        <% mark_start.call %>
      ERB
      view = build_view(template:) {
        expose(:mark_start) { -> { calls << :template_start } }
        expose!(:body) { raise "not found" }
      }

      expect { view.call }.to raise_error(RuntimeError, "not found")
      expect(calls).to eq []
    end
  end

  describe "Rendered" do
    it "resolves exposures on demand, without calling any exposure twice" do
      template = <<~ERB
        <p><%= body %></p>
      ERB
      view = build_view(template:) {
        expose(:body) { calls << :body; "Body" }
        expose(:other) { calls << :other; "Other" }
      }

      rendered = view.call
      expect(calls).to eq [:body]

      expect(rendered[:other]).to eq "Other"
      expect(calls).to eq [:body, :other]

      expect(rendered.locals).to eq(body: "Body", other: "Other")
      expect(calls).to eq [:body, :other]
    end
  end

  describe "scope locals" do
    it "provides a Locals object as `_locals` and `locals`" do
      template = <<~ERB
        <%= _locals.class %> <%= locals.class %>
      ERB
      view = build_view(template:) {}

      expect(view.call.to_s).to eq "Hanami::View::Locals Hanami::View::Locals\n"
    end
  end

  describe "dependency cycles" do
    it "raises a CyclicExposureError naming the cycle" do
      view = build_view(template: "") {
        expose(:a) { |c| c }
        expose(:b) { |a| a }
        expose(:c) { |b| b }
      }

      expect { view.call }.to raise_error(
        Hanami::View::CyclicExposureError,
        "exposures depend on each other in a cycle: a -> c -> b -> a"
      )
    end

    it "raises a CyclicExposureError for an exposure that depends on itself" do
      view = build_view(template: "") {
        expose(:a) { |a| a }
      }

      expect { view.call }.to raise_error(Hanami::View::CyclicExposureError, /a -> a/)
    end

    it "checks subclasses separately" do
      parent = build_view(template: "") {
        expose(:a) { "a" }
      }
      parent.call

      child = Class.new(parent.class) {
        expose(:a) { |b| b }
        expose(:b) { |a| a }
      }

      expect { child.new.call }.to raise_error(Hanami::View::CyclicExposureError)
    end
  end
end
