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

  describe "#current_template_name" do
    it "is nil before any render" do
      expect(renderer.current_template_name).to be_nil
    end

    it "exposes the resolved template name during a template render" do
      captured = nil
      allow(renderer).to receive(:render).and_wrap_original do |original, *args, &block|
        captured = renderer.current_template_name
        original.call(*args, &block)
      end

      renderer.template("hello", :html, scope)

      expect(captured).to eq("hello")
    end

    it "exposes the resolved partial name (without leading underscore) during a partial render" do
      captured = nil
      allow(renderer).to receive(:render).and_wrap_original do |original, *args, &block|
        captured = renderer.current_template_name
        original.call(*args, &block)
      end

      renderer.partial("hello", :html, scope)

      expect(captured).to eq("hello")
    end

    it "exposes the resolved partial name including its directory when partial is in a subdirectory" do
      captured = nil
      allow(renderer).to receive(:render).and_wrap_original do |original, *args, &block|
        captured = renderer.current_template_name
        original.call(*args, &block)
      end

      renderer.partial("shared/shared_hello", :html, scope)

      expect(captured).to eq("shared/shared_hello")
    end

    it "is restored to nil after a template render completes" do
      renderer.template("hello", :html, scope)
      expect(renderer.current_template_name).to be_nil
    end

    it "is restored even if rendering raises" do
      allow(renderer).to receive(:render).and_raise("boom")

      expect { renderer.template("hello", :html, scope) }.to raise_error("boom")
      expect(renderer.current_template_name).to be_nil
    end

    it "is unchanged when a lookup miss raises TemplateNotFoundError" do
      expect {
        renderer.template("missing", :html, scope)
      }.to raise_error(Hanami::View::TemplateNotFoundError)
      expect(renderer.current_template_name).to be_nil
    end
  end

  describe "#current_template_names" do
    it "is empty before any render" do
      expect(renderer.current_template_names).to eq([])
    end

    it "holds a single entry during a flat render" do
      captured = nil
      allow(renderer).to receive(:render).and_wrap_original do |original, *args, &block|
        captured = renderer.current_template_names.dup
        original.call(*args, &block)
      end

      renderer.template("hello", :html, scope)

      expect(captured).to eq(["hello"])
      expect(renderer.current_template_names).to eq([])
    end
  end
end
