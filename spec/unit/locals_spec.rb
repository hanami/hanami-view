# frozen_string_literal: true

RSpec.describe Hanami::View::Locals do
  subject(:locals) { described_class.new(exposures, input, decorator:) }

  let(:exposures) { Hanami::View::Exposures.new }
  let(:input) { {greeting: "hello"} }
  let(:decorator) { nil }
  let(:calls) { [] }

  before do
    calls = self.calls

    exposures.add(:greeting, -> greeting: { calls << :greeting; greeting.upcase })
    exposures.add(:farewell, -> greeting { calls << :farewell; "#{greeting} and goodbye" })
    exposures.add(:hidden, -> **_input { calls << :hidden; "shh" }, private: true)
    exposures.add(:title, -> hidden { calls << :title; "#{hidden}!" }, layout: true)
  end

  describe "#key?" do
    it "returns true for public exposures" do
      expect(locals.key?(:greeting)).to be true
    end

    it "returns false for private exposures" do
      expect(locals.key?(:hidden)).to be false
    end

    it "returns false for unknown names" do
      expect(locals.key?(:unknown)).to be false
    end

    it "resolves nothing" do
      locals.key?(:greeting)
      expect(calls).to eq []
    end
  end

  describe "#[]" do
    it "resolves only the named exposure and its dependencies" do
      expect(locals[:farewell]).to eq "HELLO and goodbye"
      expect(calls).to eq [:greeting, :farewell]
    end

    it "memoizes resolved values" do
      locals[:greeting]
      locals[:greeting]
      locals[:farewell]

      expect(calls).to eq [:greeting, :farewell]
    end

    it "memoizes nil values" do
      calls = self.calls
      exposures.add(:nothing, -> { calls << :nothing; nil })

      locals[:nothing]
      locals[:nothing]

      expect(calls).to eq [:nothing]
    end

    it "returns nil for private exposures" do
      expect(locals[:hidden]).to be nil
      expect(calls).to eq []
    end

    it "returns nil for unknown names" do
      expect(locals[:unknown]).to be nil
    end
  end

  describe "#fetch" do
    it "resolves only the named exposure" do
      expect(locals.fetch(:greeting)).to eq "HELLO"
      expect(calls).to eq [:greeting]
    end

    it "raises a KeyError for unknown names" do
      expect { locals.fetch(:unknown) }.to raise_error(KeyError, "key not found: :unknown")
    end

    it "returns a given default for unknown names" do
      expect(locals.fetch(:unknown, "default")).to eq "default"
      expect(locals.fetch(:unknown, nil)).to be nil
    end

    it "returns the result of a given block for unknown names" do
      expect(locals.fetch(:unknown) { |name| "no #{name}" }).to eq "no unknown"
    end
  end

  describe "#to_h" do
    it "resolves every exposure and returns a hash of the public locals" do
      expect(locals.to_h).to eq(greeting: "HELLO", farewell: "HELLO and goodbye", title: "shh!")
      expect(calls).to contain_exactly(:greeting, :farewell, :hidden, :title)
    end
  end

  describe "#inspect" do
    it "resolves nothing" do
      expect(locals.inspect).to eq "#<Hanami::View::Locals keys=[:greeting, :farewell, :title]>"
      expect(calls).to eq []
    end
  end

  describe "#for_layout" do
    it "contains only the exposures marked with `layout: true`" do
      layout_locals = locals.for_layout

      expect(layout_locals.key?(:title)).to be true
      expect(layout_locals.key?(:greeting)).to be false
      expect(layout_locals.to_h).to eq(title: "shh!")
    end

    it "shares resolved values with the original locals" do
      locals[:title]
      locals.for_layout[:title]

      expect(calls).to eq [:hidden, :title]
    end
  end

  describe "#resolve_eager" do
    it "resolves eager exposures and their dependencies" do
      calls = self.calls
      exposures.add(:eager, -> farewell { calls << :eager; farewell }, eager: true)

      locals.resolve_eager

      expect(calls).to eq [:greeting, :farewell, :eager]
    end
  end

  describe "decorator" do
    let(:decorator) { -> value, exposure { "#{value} (#{exposure.name})" } }

    it "decorates values as they are resolved, and passes decorated values to dependents" do
      expect(locals[:farewell]).to eq "HELLO (greeting) and goodbye (farewell)"
    end
  end

  describe "exposures with default values" do
    it "returns the default when the input has no value" do
      exposures.add(:name, default: "John")

      expect(described_class.new(exposures, {})[:name]).to eq "John"
    end

    it "returns the value from the input" do
      exposures.add(:name, default: "John")

      expect(described_class.new(exposures, {name: "William"})[:name]).to eq "William"
    end

    it "returns the value from the input, even when it is nil" do
      exposures.add(:name, default: "John")

      expect(described_class.new(exposures, {name: nil})[:name]).to be nil
    end

    it "returns the value from the exposure's proc" do
      exposures.add(:name, -> name: { name.upcase }, default: "John")

      expect(described_class.new(exposures, {name: "William"})[:name]).to eq "WILLIAM"
    end
  end
end
