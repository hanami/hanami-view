# frozen_string_literal: true

RSpec.describe "Template rendering / Current template name" do
  let(:dir) { make_tmp_directory }

  let(:context_class) {
    Class.new(Hanami::View::Context) {
      attr_reader :captures

      def initialize(captures: [])
        super()
        @captures = captures
      end

      def capture_template_name(label)
        captures << [label, current_template_name]
        ""
      end

      def capture_template_names(label)
        captures << [label, _rendering.current_template_names.dup]
        ""
      end
    }
  }

  let(:context) { context_class.new }

  def build_view(template:, layout: false)
    dir = self.dir
    Class.new(Hanami::View) {
      config.paths = dir
      config.template = template
      config.layout = layout
    }.new
  end

  it "is reported via Scope#template_name from inside a template" do
    with_directory(dir) do
      write "show.html.erb", "<%= template_name %>"
    end

    expect(build_view(template: "show").call(context:).to_s).to eq "show"
  end

  it "is reported via Context#current_template_name from inside a template" do
    with_directory(dir) do
      write "show.html.erb", "<%= _context.current_template_name %>"
    end

    expect(build_view(template: "show").call(context:).to_s).to eq "show"
  end

  it "reports the partial's file name inside a partial" do
    with_directory(dir) do
      write "show.html.erb", "<%= render('form') %>"
      write "_form.html.erb", "in:<%= template_name %>"
    end

    expect(build_view(template: "show").call(context:).to_s).to eq "in:_form"
  end

  it "reports the partial's resolved path (not just its lookup name)" do
    with_directory(dir) do
      Dir.mkdir(File.join(dir, "posts"))
      File.write(File.join(dir, "posts", "show.html.erb"), "<%= render('form') %>")
      File.write(File.join(dir, "posts", "_form.html.erb"), "in:<%= template_name %>")
    end

    expect(build_view(template: "posts/show").call(context:).to_s).to eq "in:posts/_form"
  end

  it "preserves explicit qualified partial paths" do
    with_directory(dir) do
      Dir.mkdir(File.join(dir, "shared"))
      File.write(File.join(dir, "show.html.erb"), "<%= render('shared/form') %>")
      File.write(File.join(dir, "shared", "_form.html.erb"), "in:<%= template_name %>")
    end

    expect(build_view(template: "show").call(context:).to_s).to eq "in:shared/_form"
  end

  it "reports the layout's name from inside the layout" do
    with_directory(dir) do
      Dir.mkdir(File.join(dir, "layouts"))
      File.write(File.join(dir, "layouts", "app.html.erb"), "L:<%= template_name %>|<%= yield %>")
      write "show.html.erb", "T:<%= template_name %>"
    end

    expect(build_view(template: "show", layout: "app").call(context:).to_s).to eq "L:layouts/app|T:show"
  end

  it "exposes the full stack via current_template_names at each level of nesting" do
    with_directory(dir) do
      write "show.html.erb", <<~ERB
        <%= capture_template_names(:show) %><%= render('outer') %>
      ERB
      write "_outer.html.erb", <<~ERB
        <%= capture_template_names(:outer) %><%= render('inner') %>
      ERB
      write "_inner.html.erb", <<~ERB
        <%= capture_template_names(:inner) %>
      ERB
    end

    build_view(template: "show").call(context:).to_s

    expect(context.captures).to eq([
      [:show, ["show"]],
      [:outer, ["show", "_outer"]],
      [:inner, ["show", "_outer", "_inner"]]
    ])
  end

  it "restores the outer template name after a partial returns" do
    with_directory(dir) do
      write "show.html.erb", <<~ERB
        before:<%= capture_template_name(:before) %><%= render('form') %>after:<%= capture_template_name(:after) %>
      ERB
      write "_form.html.erb", "in:<%= capture_template_name(:in) %>"
    end

    build_view(template: "show").call(context:).to_s

    expect(context.captures).to eq([
      [:before, "show"],
      [:in, "_form"],
      [:after, "show"]
    ])
  end
end
