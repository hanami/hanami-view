# frozen_string_literal: true

RSpec.describe Hanami::View::Rendered do
  subject(:rendered) {
    described_class.new(
      output: "rendered template output",
      locals: {
        user: {name: "Jane"}
      }
    )
  }

  describe "#to_s" do
    it "returns the rendered output" do
      expect(rendered.to_s).to eq "rendered template output"
    end
  end

  describe "#to_str" do
    it "returns the rendered output" do
      expect(rendered.to_str).to eq "rendered template output"
    end
  end

  describe "#match?" do
    it "matches rendered output" do
      expect(rendered).to match("rendered template output")
    end

    it "is aliased as #match" do
      expect(rendered.match?("rendered template output")).to be(true)
      expect(rendered.match("rendered template output")).to be(true)
    end
  end

  describe "#include?" do
    it "matches rendered output" do
      expect(rendered).to include("rendered template output")
    end
  end

  describe "#==" do
    it "is true for a Rendered with the same output, whatever its locals" do
      other = described_class.new(output: "rendered template output", locals: {other: "locals"})

      expect(rendered).to eq other
    end

    it "is false for a Rendered with different output" do
      other = described_class.new(output: "other output", locals: {user: {name: "Jane"}})

      expect(rendered).not_to eq other
    end

    it "compares against Strings, in either direction" do
      expect(rendered).to eq "rendered template output"
      expect("rendered template output").to eq rendered
      expect(rendered).not_to eq "other output"
    end

    it "is false for other objects" do
      expect(rendered).not_to eq Object.new
    end
  end

  describe "#eql? and #hash" do
    it "match a Rendered with the same output" do
      other = described_class.new(output: "rendered template output", locals: {})

      expect(rendered).to eql other
      expect(rendered.hash).to eq other.hash
    end

    it "do not match Strings" do
      expect(rendered).not_to eql "rendered template output"
    end
  end

  describe "#locals" do
    it "returns the locals hash" do
      expect(rendered.locals).to eql(user: {name: "Jane"})
    end
  end

  describe "#[]" do
    it "returns the named local" do
      expect(rendered[:user]).to eql(name: "Jane")
    end
  end
end
