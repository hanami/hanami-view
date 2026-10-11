# frozen_string_literal: true

RSpec.describe "Template rendering / Partial lookup" do
  let(:dir) { make_tmp_directory }

  def build_view(template:, layout: false, paths: dir)
    Class.new(Hanami::View) {
      config.paths = paths
      config.template = template
      config.layout = layout
    }.new
  end

  def write_template(*segments, content, base: dir)
    path = File.join(base, *segments)
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

  describe "when the same partial name exists in more than one directory" do
    it "prefers the partial in the directory of the template rendering it" do
      write_template("_form.html.erb", "root[<%= template_name %>]")
      write_template("posts", "_form.html.erb", "posts[<%= template_name %>]")
      write_template("posts", "show.html.erb", "<%= render('form') %>")

      expect(build_view(template: "posts/show").call.to_s).to eq "posts[posts/_form]"
    end

    it "falls back to the root when the template's own directory has no match" do
      write_template("_form.html.erb", "root[<%= template_name %>]")
      write_template("posts", "show.html.erb", "<%= render('form') %>")

      expect(build_view(template: "posts/show").call.to_s).to eq "root[_form]"
    end

    it "prefers the deepest directory in the render chain" do
      write_template("_form.html.erb", "root[<%= template_name %>]")
      write_template("posts", "_form.html.erb", "posts[<%= template_name %>]")
      write_template("posts", "comments", "_form.html.erb", "comments[<%= template_name %>]")
      write_template("posts", "comments", "_list.html.erb", "<%= render('form') %>")
      write_template("posts", "show.html.erb", "<%= render('comments/list') %>")

      expect(build_view(template: "posts/show").call.to_s).to eq "comments[posts/comments/_form]"
    end

    it "walks outward through enclosing directories before reaching the root" do
      write_template("_form.html.erb", "root[<%= template_name %>]")
      write_template("posts", "_form.html.erb", "posts[<%= template_name %>]")
      write_template("posts", "comments", "_list.html.erb", "<%= render('form') %>")
      write_template("posts", "show.html.erb", "<%= render('comments/list') %>")

      expect(build_view(template: "posts/show").call.to_s).to eq "posts[posts/_form]"
    end

    it "prefers a deeper directory in a later view path over the root of an earlier one" do
      other_dir = make_tmp_directory

      write_template("_form.html.erb", "first[<%= template_name %>]", base: other_dir)
      write_template("posts", "_form.html.erb", "second[<%= template_name %>]")
      write_template("posts", "show.html.erb", "<%= render('form') %>")

      expect(build_view(template: "posts/show", paths: [other_dir, dir]).call.to_s)
        .to eq "second[posts/_form]"
    end

    it "prefers an earlier view path when both hold the partial in the same directory" do
      other_dir = make_tmp_directory

      write_template("posts", "_form.html.erb", "first[<%= template_name %>]", base: other_dir)
      write_template("posts", "_form.html.erb", "second[<%= template_name %>]")
      write_template("posts", "show.html.erb", "<%= render('form') %>")

      expect(build_view(template: "posts/show", paths: [other_dir, dir]).call.to_s)
        .to eq "first[posts/_form]"
    end
  end
end
