# frozen_string_literal: true

require "tilt/erubi"

RSpec.describe Hanami::View do
  subject(:view) {
    Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.layout = "app"
      config.template = "user"

      expose :user do
        {name: "Jane"}
      end

      expose :header do
        {title: "User"}
      end
    end.new
  }

  let(:context) do
    Class.new(Hanami::View::Context) do
      def title
        "Test"
      end
    end.new
  end

  describe "#call" do
    it "renders template within the layout" do
      expect(view.(context: context).to_s).to eql(
        "<!DOCTYPE html><html><head><title>Test</title></head><body><h1>User</h1><p>Jane</p></body></html>"
      )
    end

    it "allows a different layout to be passed to call" do
      expect(view.(context: context, layout: "alternate").to_s).to eql(
        "<!DOCTYPE html><html><head><title>Alternate layout Test</title></head><body><h1>User</h1><p>Jane</p></body></html>"
      )
    end

    it "allows a nil layout to be passed to call" do
      expect(view.(context: context, layout: nil).to_s).to eql(
        "<h1>User</h1><p>Jane</p>"
      )
    end
  end

  describe "template caching" do
    let(:view_class) { view.class }

    it "reuses compiled templates across instances of the same view class" do
      view_class.new.(context: context)

      expect { view_class.new.(context: context) }
        .not_to change { Hanami::View.cache.cache.size }
    end

    it "finalizes the config before sharing it" do
      subclass = Class.new(view_class)

      expect(subclass.config_data).to be(subclass.config_data)
      expect(subclass.config).to be_frozen
    end

    it "keeps separate caches for subclasses" do
      subclass = Class.new(view_class) { config.layout = "alternate" }

      expect(subclass.new.(context: context).to_s).to include("Alternate layout")
      expect(view_class.new.(context: context).to_s).not_to include("Alternate layout")
    end
  end

  describe "layout rendering" do
    subject(:view) {
      Class.new(Hanami::View) {
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.layout = "missing_layout"
        config.template = "user"

        expose :user do
          {name: "Jane"}
        end

        expose :header do
          {title: "User"}
        end
      }.new
    }

    it "raises a LayoutNotFoundError error when layout cannot be found" do
      expect { view.() }.to raise_error Hanami::View::TemplateNotFoundError, %r{Template `layouts/missing_layout' for format `html' could not be found}
    end
  end

  describe "template rendering" do
    it "raises a TemplateNotFoundError when the template cannot be found" do
      view = Class.new(Hanami::View) {
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.layout = nil
        config.template = "missing_template"
      }.new

      expect { view.() }.to raise_error Hanami::View::TemplateNotFoundError, /Template `missing_template' for format `html' could not be found/
    end

    it "raises a TemplateNotFoundError when a partial cannot be found from inside the layout" do
      view = Class.new(Hanami::View) {
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.layout = "missing_partial"
        config.template = "empty"
      }.new

      expect { view.() }.to raise_error Hanami::View::TemplateNotFoundError, /Template `_missing_partial' for format `html' could not be found/
    end
  end

  describe "renderer options" do
    subject(:view) {
      Class.new(Hanami::View) do
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.template = "view_renderer_options"
        config.renderer_engine_mapping = {erb: Tilt::ErubiTemplate}
        config.renderer_options = {outvar: "@__buf__"}
      end.new
    }

    before do
      module Test
        class Form
          def initialize(action, &block)
            @buf = eval("@__buf__", block.binding, __FILE__, __LINE__)

            @buf << "<form action=\"#{action}\" method=\"post\">"
            block.(self)
            @buf << "</form>"
          end

          def text(name)
            "<input type=\"text\" name=\"#{name}\" />"
          end
        end
      end
    end

    subject(:context) {
      Class.new(Hanami::View::Context) do
        def form(action:, &blk)
          Test::Form.new(action, &blk)
        end
      end.new
    }

    it "merges configured options with default encoding" do
      expect(view.class.config.renderer_options[:outvar]).to eq "@__buf__"
      expect(view.class.config.renderer_options[:default_encoding]).to eq "utf-8"
    end

    it "are passed to renderer" do
      expect(view.(context: context).to_s.gsub(/\n\s*/m, "")).to eq(
        '<form action="/people" method="post"><input type="text" name="name" /></form>'
      )
    end
  end
end
