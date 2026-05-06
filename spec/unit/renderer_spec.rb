# frozen_string_literal: true

RSpec.describe Hanami::View::Renderer do
  subject(:renderer) { Hanami::View::Renderer.new(config_data) }

  let(:config_data) { view_class.config.to_data }

  let(:view_class) {
    Class.new(Hanami::View) {
      config.paths = Hanami::View::Path.new(SPEC_ROOT.join("fixtures/templates"))
      finalize!
    }
  }

  let(:scope) { double(:scope, _locals: {}) }

  describe "#template" do
    it "renders template in a path root" do
      expect(renderer.template("hello", :html, scope)).to eql("<h1>Hello</h1>")
    end

    it "raises error when template cannot be found" do
      expect {
        renderer.template("missing_template", :html, scope)
      }.to raise_error(Hanami::View::TemplateNotFoundError, /missing_template.*html/)
    end
  end

  describe "#partial" do
    it "renders partial in a path root" do
      expect(renderer.partial("hello", :html, scope)).to eql("<h1>Partial hello</h1>")
    end

    it "renders partial in a subdirectory" do
      expect(renderer.partial("shared/shared_hello", :html, scope)).to eql("<h1>Hello</h1>")
    end

    it "raises error when partial cannot be found" do
      expect {
        renderer.partial("missing_partial", :html, scope)
      }.to raise_error(Hanami::View::TemplateNotFoundError, /_missing_partial/)
    end
  end
end
