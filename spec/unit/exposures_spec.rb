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

    it "is shared with bound copies" do
      exposures.add(:a, -> **_input { "a" }, eager: true)

      expect(exposures.bind(Object.new).eager_names).to be exposures.eager_names
    end

    it "is recomputed after an exposure is added" do
      exposures.add(:a, -> **_input { "a" }, eager: true)
      exposures.eager_names
      exposures.add(:b, -> **_input { "b" }, eager: true)

      expect(exposures.eager_names).to eq [:a, :b]
    end
  end

  describe "#ensure_acyclic" do
    it "does nothing when there are no cycles" do
      exposures.add(:a, -> **_input { "a" })
      exposures.add(:b, -> a, missing { a })

      expect { exposures.ensure_acyclic }.not_to raise_error
    end

    it "raises a CyclicExposureError naming the cycle" do
      exposures.add(:a, -> b { b })
      exposures.add(:b, -> a { a })

      expect { exposures.ensure_acyclic }.to raise_error(Hanami::View::CyclicExposureError) { |error|
        expect(error.cycle).to eq [:a, :b, :a]
      }
    end

    it "shares its result with bound copies" do
      exposures.add(:a, -> **_input { "a" })
      exposures.ensure_acyclic

      # Add a cycle without going through #add, which would replace the cache. A bound copy still
      # uses the shared result, so it does not check again.
      exposures.exposures[:a] = Hanami::View::Exposure.new(:a, -> a { a })

      expect { exposures.bind(Object.new).ensure_acyclic }.not_to raise_error
    end

    it "checks again after an exposure is added" do
      exposures.add(:a, -> **_input { "a" })
      exposures.ensure_acyclic
      exposures.add(:b, -> b { b })

      expect { exposures.ensure_acyclic }.to raise_error(Hanami::View::CyclicExposureError)
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
