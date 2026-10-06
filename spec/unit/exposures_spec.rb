# frozen_string_literal: true

RSpec.describe Hanami::View::Exposures do
  subject(:exposures) { described_class.new }

  describe "#exposures" do
    it "is empty by default" do
      expect(exposures.exposures).to be_empty
    end
  end

  describe "#add" do
    it "creates and adds an exposure" do
      proc = -> **_input { "hi" }
      exposures.add :hello, proc

      expect(exposures[:hello].name).to eq :hello
      expect(exposures[:hello].proc).to eq proc
    end
  end

  describe "#bind" do
    subject(:bound_exposures) { exposures.bind(object) }

    let(:object) do
      Class.new do
        def hello(_input)
          "hi"
        end
      end.new
    end

    before do
      exposures.add(:hello)
    end

    it "binds each of the exposures" do
      expect(bound_exposures[:hello].proc).to eq object.method(:hello)
    end

    it "returns a new copy of the exposures" do
      expect(exposures.exposures).not_to eql(bound_exposures.exposures)
    end
  end

  describe "#eager_names" do
    it "returns eager exposures and their dependencies, all the way down" do
      exposures.add(:a, -> **_input { "a" })
      exposures.add(:b, -> a { a })
      exposures.add(:c, -> b { b }, eager: true)
      exposures.add(:d, -> **_input { "d" })

      expect(exposures.eager_names).to contain_exactly(:a, :b, :c)
    end

    it "is worked out again for bound copies, using the dependencies of exposures defined as methods" do
      exposures.add(:a, -> **_input { "a" })
      exposures.add(:b, eager: true)

      object = Class.new { def b(a) = a }.new

      expect(exposures.eager_names).to eq [:b]
      expect(exposures.bind(object).eager_names).to eq [:b, :a]
    end

    it "is recomputed after an exposure is added" do
      exposures.add(:a, -> **_input { "a" }, eager: true)
      exposures.eager_names
      exposures.add(:b, -> **_input { "b" }, eager: true)

      expect(exposures.eager_names).to eq [:a, :b]
    end
  end

  describe "#public_names" do
    it "returns the names of the exposures that are not private" do
      exposures.add(:a, -> **_input { "a" })
      exposures.add(:b, -> **_input { "b" }, private: true)

      expect(exposures.public_names).to eq Set[:a]
    end
  end

  describe "#layout_names" do
    it "returns the names of the public exposures marked with `layout: true`" do
      exposures.add(:a, -> **_input { "a" }, layout: true)
      exposures.add(:b, -> **_input { "b" })
      exposures.add(:c, -> **_input { "c" }, layout: true, private: true)

      expect(exposures.layout_names).to eq Set[:a]
    end
  end

  describe "dependency cycles" do
    let(:object) { Object.new }

    it "does not raise when there are no cycles" do
      exposures.add(:a, -> **_input { "a" })
      exposures.add(:b, -> a, missing { a })

      expect { exposures.bind(object) }.not_to raise_error
    end

    it "raises a CyclicExposureError naming the cycle when binding" do
      exposures.add(:a, -> b { b })
      exposures.add(:b, -> a { a })

      expect { exposures.bind(object) }.to raise_error(Hanami::View::CyclicExposureError) { |error|
        expect(error.cycle).to eq [:a, :b, :a]
      }
    end

    it "includes the dependencies of exposures defined as methods" do
      exposures.add(:a, -> b { b })
      exposures.add(:b)

      object = Class.new { def b(a) = a }.new

      expect { exposures.bind(object) }.to raise_error(Hanami::View::CyclicExposureError) { |error|
        expect(error.cycle).to eq [:a, :b, :a]
      }
    end

    it "raises when creating a set of exposures" do
      cyclic = {a: Hanami::View::Exposure.new(:a, -> a { a })}

      expect { described_class.new(cyclic) }.to raise_error(Hanami::View::CyclicExposureError)
    end

    it "does not raise when adding exposures" do
      exposures.add(:a, -> b { b })

      expect { exposures.add(:b, -> a { a }) }.not_to raise_error
    end
  end

  describe "#import" do
    it "imports an exposure to the set" do
      exposures_b = described_class.new
      exposures.add(:name, -> name: { name.upcase }, default: "John")
      exposures_b.import(:name, exposures[:name])

      expect(exposures_b[:name]).to eq(exposures[:name])
    end
  end
end
