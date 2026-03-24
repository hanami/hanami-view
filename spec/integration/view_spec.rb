# frozen_string_literal: true

RSpec.describe "hanami-view" do
  let(:view_class) do
    Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.layout = "app"
      config.template = "users"
      config.default_format = :html

      expose :users, decorate: true do
        [
          {name: "Jane", email: "jane@doe.org"},
          {name: "Joe", email: "joe@doe.org"}
        ]
      end
    end
  end

  let(:context) {
    Class.new(Hanami::View::Context) do
      def title
        "hanami-view rocks!"
      end

      def assets
        -> input { "#{input}.jpg" }
      end
    end.new
  }

  it "renders within a layout and makes the provided context available everywhere" do
    view = view_class.new

    expect(view.(context: context).to_s).to eql(
      '<!DOCTYPE html><html><head><title>hanami-view rocks!</title></head><body><div class="users"><table><tbody><tr><td>Jane</td><td>jane@doe.org</td></tr><tr><td>Joe</td><td>joe@doe.org</td></tr></tbody></table></div><img src="mindblown.jpg" /></body></html>'
    )
  end

  it "renders without a layout" do
    view = Class.new(view_class) do
      config.layout = false
    end.new

    expect(view.(context: context).to_s).to eql(
      '<div class="users"><table><tbody><tr><td>Jane</td><td>jane@doe.org</td></tr><tr><td>Joe</td><td>joe@doe.org</td></tr></tbody></table></div><img src="mindblown.jpg" />'
    )
  end

  it "renders a view with an alternative format and engine" do
    view = view_class.new

    expect(view.(context: context, format: "txt").to_s.strip).to eql(
      "# hanami-view rocks!\n\n* Jane (jane@doe.org)\n* Joe (joe@doe.org)"
    )
  end

  it "renders a view with a template on another view path" do
    view = Class.new(view_class) do
      config.paths = [SPEC_ROOT.join("fixtures/templates_override")] + Array(config.paths)
    end.new

    expect(view.(context: context).to_s).to eq(
      '<!DOCTYPE html><html><head><title>hanami-view rocks!</title></head><body><h1>OVERRIDE</h1><div class="users"><table><tbody><tr><td>Jane</td><td>jane@doe.org</td></tr><tr><td>Joe</td><td>joe@doe.org</td></tr></tbody></table></div></body></html>'
    )
  end

  it "renders a view that passes arguments to partials" do
    view = Class.new(view_class) do
      config.template = "parts_with_args"
    end.new

    expect(view.(context: context).to_s).to eq(
      '<!DOCTYPE html><html><head><title>hanami-view rocks!</title></head><body><div class="users"><div class="box"><h2>Nombre</h2>Jane</div><div class="box"><h2>Nombre</h2>Joe</div></div></body></html>'
    )
  end

  it "renders using utf-8 by default" do
    view = Class.new(view_class) do
      config.template = "utf8"
    end.new

    expect(view.(context: context).to_s).to eq(
      "<!DOCTYPE html><html><head><title>hanami-view rocks!</title></head><body>ç</body></html>"
    )
  end

  describe "inheritance" do
    let(:parent_view) do
      klass = Class.new(Hanami::View)

      klass.setting :paths, SPEC_ROOT.join("fixtures/templates")
      klass.setting :layout, "app"
      klass.setting :formats, html: :slim

      klass
    end

    let(:child_view) do
      Class.new(parent_view) do
        config.template = "tasks"
      end
    end

    it "renders within a parent class layout using provided context" do
      view = Class.new(view_class) do
        config.template = "tasks"

        expose :tasks do
          [
            {title: "one"},
            {title: "two"}
          ]
        end
      end.new

      expect(view.(context: context).to_s).to eql(
        "<!DOCTYPE html><html><head><title>hanami-view rocks!</title></head><body><ol><li>one</li><li>two</li></ol></body></html>"
      )
    end
  end
end
