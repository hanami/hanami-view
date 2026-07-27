# frozen_string_literal: true

RSpec.describe "Template rendering / Partial lookup" do
  let(:dir) { make_tmp_directory }

  def build_view(template:, layout: false)
    dir = self.dir
    Class.new(Hanami::View) {
      config.paths = dir
      config.template = template
      config.layout = layout
    }.new
  end

  def write_template(*segments, content)
    path = File.join(dir, *segments)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  it "finds a bare-named partial alongside the template rendering it" do
    write_template("users", "index.html.erb", "<%= render('form') %>")
    write_template("users", "_form.html.erb", "[<%= template_name %>]")

    expect(build_view(template: "users/index").call.to_s).to eq "[users/_form]"
  end

  it "finds a bare-named partial alongside the partial rendering it, at any depth" do
    write_template("devices", "show.html.erb", "<%= render('shared/fields') %>")
    write_template("devices", "shared", "_fields.html.erb", "<%= render('popovers/all') %>")
    write_template("devices", "shared", "popovers", "_all.html.erb", "<%= render('command') %>")
    write_template("devices", "shared", "popovers", "_command.html.erb", "[<%= template_name %>]")

    expect(build_view(template: "devices/show").call.to_s)
      .to eq "[devices/shared/popovers/_command]"
  end

  it "does not escape into a same-named directory at the root" do
    write_template("devices", "show.html.erb", "<%= render('shared/fields') %>")
    write_template("devices", "shared", "_fields.html.erb", "<%= render('popovers/all') %>")
    write_template("devices", "shared", "popovers", "_all.html.erb", "nested[<%= template_name %>]")
    # An unrelated top-level `shared/` tree, which must not be reached from `devices/shared/`.
    write_template("shared", "popovers", "_all.html.erb", "root[<%= template_name %>]")

    expect(build_view(template: "devices/show").call.to_s)
      .to eq "nested[devices/shared/popovers/_all]"
  end

  it "still resolves a partial named by its full path from the root" do
    write_template("devices", "show.html.erb", "<%= render('shared/popovers/all') %>")
    write_template("shared", "popovers", "_all.html.erb", "[<%= template_name %>]")

    expect(build_view(template: "devices/show").call.to_s).to eq "[shared/popovers/_all]"
  end

  it "restores the prefix stack after a nested render returns" do
    write_template("devices", "show.html.erb", "<%= render('shared/fields') %><%= render('sibling') %>")
    write_template("devices", "shared", "_fields.html.erb", "")
    write_template("devices", "_sibling.html.erb", "[<%= template_name %>]")

    expect(build_view(template: "devices/show").call.to_s).to eq "[devices/_sibling]"
  end
end
