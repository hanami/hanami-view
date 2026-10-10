# frozen_string_literal: true

# These adapters are ignored by our Zeitwerk loader, since they require the optional "haml" and
# "slim" gems. Load them explicitly for these tests.
require "hanami/view/tilt/haml_adapter"
require "hanami/view/tilt/slim_adapter"

RSpec.describe "Template rendering / fixed locals" do
  %w[erb haml slim].each do |engine|
    describe "in #{engine} templates" do
      let(:view) {
        Class.new(Hanami::View) do
          config.paths = FIXTURES_PATH.join("integration/template_rendering/fixed_locals", engine)
          config.template = "greeting"

          expose :partial_locals, decorate: false
        end.new
      }

      it "renders the locals given, filling in defaults for the rest" do
        expect(view.(partial_locals: {name: "Jane"}).to_s.strip).to eq "Hello, Jane!"
        expect(view.(partial_locals: {name: "Jane", greeting: "Kia ora"}).to_s.strip).to eq "Kia ora, Jane!"
      end

      it "raises for a missing local" do
        expect { view.(partial_locals: {greeting: "Kia ora"}) }.to raise_error(ArgumentError, /missing keyword: :name/)
      end

      it "raises for an unknown local" do
        expect { view.(partial_locals: {name: "Jane", nmae: "Jane"}) }.to raise_error(ArgumentError, /unknown keyword: :nmae/)
      end

      it "ignores the declaration's syntax appearing outside a comment" do
        view = Class.new(Hanami::View) do
          config.paths = FIXTURES_PATH.join("integration/template_rendering/fixed_locals", engine)
          config.template = "mentioned"

          expose :title
        end.new

        expect(view.(title: "Profile").to_s).to include "locals: (user:)"
      end

      it "ends the declaration at its closing parenthesis, ignoring text after it" do
        view = Class.new(Hanami::View) do
          config.paths = FIXTURES_PATH.join("integration/template_rendering/fixed_locals", engine)
          config.template = "described"

          expose :title
        end.new

        expect(view.(title: "Profile").to_s.strip).to eq "Profile"

        view = Class.new(view.class) { expose :subtitle }.new
        expect { view.(title: "Profile", subtitle: "Mine") }.to raise_error(ArgumentError, /unknown keyword: :subtitle/)
      end
    end
  end

  describe "in an ERB comment" do
    def render_template(template, **exposures)
      Class.new(Hanami::View) do
        config.paths = FIXTURES_PATH.join("integration/template_rendering/fixed_locals/erb")
        config.template = template

        exposures.each_key { |name| expose name }
      end.new.(**exposures).to_s.strip
    end

    it "ends the declaration with its tag, ignoring parentheses after it" do
      expect(render_template("followed", title: "Profile")).to eq "Profile (see the docs)"
    end

    it "reads a declaration spanning several lines" do
      expect(render_template("multiline", title: "Profile")).to eq "Profile, Mine"
    end
  end

  describe "in a view template" do
    let(:view_class) {
      Class.new(Hanami::View) do
        config.paths = FIXTURES_PATH.join("integration/template_rendering/fixed_locals/erb")
        config.template = "titled"
      end
    }

    it "declares the exposures the template takes" do
      view = Class.new(view_class) { expose :title }.new

      expect(view.(title: "Profile").to_s.strip).to eq "<h1>Profile</h1>"
    end

    it "raises for an exposure the template does not declare" do
      view = Class.new(view_class) {
        expose :title
        expose :subtitle
      }.new

      expect { view.(title: "Profile", subtitle: "Mine") }.to raise_error(ArgumentError, /unknown keyword: :subtitle/)
    end
  end

  describe "in a partial" do
    def render_template(template)
      Class.new(Hanami::View) do
        config.paths = FIXTURES_PATH.join("integration/template_rendering/fixed_locals/erb")
        config.template = template

        expose :title
      end.new.(title: "Profile").to_s.strip
    end

    it "receives none of its caller's locals when rendered without arguments" do
      expect { render_template("shared_scope") }.to raise_error(ArgumentError, /missing keyword: :title/)
    end

    it "receives none of its caller's locals when rendered without arguments inside a yielded block" do
      expect { render_template("yielded_scope") }.to raise_error(ArgumentError, /missing keyword: :title/)
    end

    it "cannot read its caller's locals by name when rendered without arguments" do
      expect { render_template("peek_scope") }.to raise_error(NameError, /title/)
    end

    it "receives the locals passed to it" do
      expect(render_template("passed_scope")).to eq "<h1>Profile</h1>"
    end

    it "receives the locals of a scope built for it" do
      expect(render_template("built_scope")).to eq "<h1>Profile</h1>"
    end

    it "renders without arguments from a scope class requiring its locals when built" do
      view = Class.new(Hanami::View) do
        config.paths = FIXTURES_PATH.join("integration/template_rendering/fixed_locals/erb")
        config.template = "plain_scope"
        config.scope = Class.new(Hanami::View::Scope) {
          def initialize(locals:, **)
            super
          end
        }
      end.new

      expect(view.().to_s.strip).to eq "Plain"
    end
  end

  describe "with extract_fixed_locals turned off" do
    it "renders a declaring template as any other, ignoring the comment" do
      view = Class.new(Hanami::View) do
        config.paths = FIXTURES_PATH.join("integration/template_rendering/fixed_locals/erb")
        config.renderer_options = {extract_fixed_locals: false}
        config.template = "titled"

        expose :title
        expose :subtitle
      end.new

      expect(view.(title: "Profile", subtitle: "Mine").to_s.strip).to eq "<h1>Profile</h1>"
    end
  end
end
