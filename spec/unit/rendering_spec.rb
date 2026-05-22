# frozen_string_literal: true

RSpec.describe Hanami::View::Rendering do
  subject(:rendering) { view.rendering(format: :html) }

  let(:view) {
    Class.new(Hanami::View) {
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "hello"
    }.new
  }

  let(:scope) { rendering.scope({}) }

  describe "#current_template_name" do
    it "is nil before any render" do
      expect(rendering.current_template_name).to be_nil
    end

    it "is the template's name during a template render" do
      captured = nil
      allow(rendering.renderer).to receive(:template).and_wrap_original do |original, *args, &block|
        captured = rendering.current_template_name
        original.call(*args, &block)
      end

      rendering.template("hello", scope)

      expect(captured).to eq("hello")
    end

    it "is the partial's name (without leading underscore) during a partial render" do
      captured = nil
      allow(rendering.renderer).to receive(:partial).and_wrap_original do |original, *args, &block|
        captured = rendering.current_template_name
        original.call(*args, &block)
      end

      rendering.partial("hello", scope)

      expect(captured).to eq("hello")
    end

    it "is restored to nil after a template render completes" do
      rendering.template("hello", scope)
      expect(rendering.current_template_name).to be_nil
    end

    it "is restored even if rendering raises" do
      allow(rendering.renderer).to receive(:template).and_raise("boom")

      expect { rendering.template("hello", scope) }.to raise_error("boom")
      expect(rendering.current_template_name).to be_nil
    end

    it "exposes pushed names as strings" do
      captured = nil
      allow(rendering.renderer).to receive(:template) do
        captured = rendering.current_template_name
      end

      rendering.template(:hello, scope)

      expect(captured).to eq("hello")
    end
  end

  describe "#current_template_names" do
    it "is empty before any render" do
      expect(rendering.current_template_names).to eq([])
    end

    it "holds a single entry during a flat render" do
      captured = nil
      allow(rendering.renderer).to receive(:template).and_wrap_original do |original, *args, &block|
        captured = rendering.current_template_names.dup
        original.call(*args, &block)
      end

      rendering.template("hello", scope)

      expect(captured).to eq(["hello"])
      expect(rendering.current_template_names).to eq([])
    end
  end
end
