# frozen_string_literal: true

RSpec.describe Hanami::View::Exposure do
  subject(:exposure) { described_class.new(:hello, proc, object, **options) }

  let(:proc) { -> _input { "hi" } }
  let(:object) { nil }
  let(:options) { {} }

  describe "initialization and attributes" do
    describe "#name" do
      it "accepts a name" do
        expect(exposure.name).to eql :hello
      end
    end

    describe "#proc" do
      it "accepts a proc" do
        expect(exposure.proc).to eql proc
      end

      it "allows a nil proc" do
        expect(described_class.new(:hello).proc).to be_nil
      end
    end

    describe "#object" do
      let(:object) { Object.new }

      it "accepts an object" do
        expect(exposure.object).to eq object
      end

      it "allows a nil object" do
        expect(described_class.new(:hello).object).to be_nil
      end
    end

    describe "#decorate?" do
      it "is true by default" do
        expect(exposure.decorate?).to eq true
      end

      it "can be set on initialization" do
        expect(described_class.new(:hello, decorate: false).decorate?).to eq false
      end
    end

    describe "#private?" do
      it "is false by default" do
        expect(exposure).not_to be_private
      end

      it "can be set on initialization" do
        expect(described_class.new(:hello, private: true)).to be_private
      end
    end

    describe "#default_value" do
      it "is nil by default" do
        expect(exposure.default_value).to be_nil
      end

      it "can be set on initialization" do
        exposuse = described_class.new(:hello, default: "Hi !")
        expect(exposuse.default_value).to eq("Hi !")
      end
    end
  end

  describe "#bind" do
    subject(:bound_exposure) { exposure.bind(bind_object) }

    let(:bind_object) { Object.new }

    it "returns a new object" do
      expect(bound_exposure).not_to eql exposure
    end

    it "retains the bind object" do
      expect(bound_exposure.object).to eq bind_object
    end

    context "proc is set" do
      it "retains the existing proc" do
        expect(bound_exposure.proc).to eql proc
      end
    end

    context "proc is nil" do
      let(:proc) { nil }

      context "matching instance method" do
        let(:bind_object) do
          Class.new do
            def hello(input)
              "hi there, #{input.fetch(:name)}"
            end
          end.new
        end

        it "sets the proc to the method on the object matching the exposure's name" do
          expect(bound_exposure.proc).to eql bind_object.method(:hello)
        end
      end

      context "no matching instance method" do
        let(:object) { Object.new }

        it "leaves proc as nil" do
          expect(bound_exposure.proc).to be_nil
        end
      end
    end
  end

  describe "#dependency_names" do
    context "proc provided" do
      let(:proc) { -> input, foo, bar { "hi" } }

      it "returns an array of exposure dependencies derived from the proc's argument names" do
        expect(exposure.dependency_names).to eql [:input, :foo, :bar]
      end
    end

    context "matching instance method" do
      let(:proc) { nil }

      let(:object) do
        Class.new do
          def hello(input, bar, baz)
            "hi there, #{input.fetch(:name)}"
          end
        end.new
      end

      it "returns an array of exposure dependencies derived from the instance method's argument names" do
        expect(exposure.dependency_names).to eql [:input, :bar, :baz]
      end
    end

    context "proc is nil" do
      let(:proc) { nil }

      it "returns no dependencies" do
        expect(exposure.dependency_names).to eql []
      end
    end
  end

  describe "#call" do
    let(:input) { {name: "Jane"} }

    context "proc expects input only" do
      let(:proc) { -> name: { name } }

      it "sends the input to the proc" do
        expect(exposure.(input)).to eql "Jane"
      end
    end

    context "proc expects input and dependencies" do
      let(:proc) { -> greeting, name: { "#{greeting}, #{name}" } }
      let(:locals) { {greeting: "Hola"} }

      it "sends the input and dependency values to the proc" do
        expect(exposure.(input, locals)).to eq "Hola, Jane"
      end
    end

    context "Default value" do
      let(:options) { {default: "John"} }

      context "use default value" do
        let(:proc) { nil }

        it "use the default value" do
          expect(exposure.({})).to eq "John"
        end
      end

      context "use input value instead of default" do
        let(:proc) { nil }

        it "use the default value" do
          expect(exposure.(hello: "Jane")).to eq "Jane"
        end
      end

      context "use input value over default even when input is nil" do
        let(:proc) { nil }

        it "use the default value" do
          expect(exposure.(hello: nil)).to eq nil
        end
      end
    end

    context "proc expects dependencies only" do
      let(:proc) { -> greeting, farewell { "#{greeting}, #{farewell}" } }
      let(:locals) { {greeting: "Hola", farewell: "Adios"} }

      it "sends the dependency values to the proc" do
        expect(exposure.(input, locals)).to eq "Hola, Adios"
      end
    end

    context "proc accesses object instance" do
      let(:proc) { -> name: { "My name is #{name} but call me #{title} #{name}" } }

      let(:object) do
        Class.new do
          attr_reader :title

          def initialize(title)
            @title = title
          end
        end.new("Dr")
      end

      it "makes the instance available as self" do
        expect(exposure.(input)).to eq "My name is Jane but call me Dr Jane"
      end
    end

    context "no proc" do
      let(:proc) { nil }
      let(:input) { {hello: "hi there"} }

      it "returns a matching key from the input" do
        expect(exposure.(input)).to eq "hi there"
      end

      it "returns nil when no input key matches" do
        expect(exposure.(nothing_matches_here: true)).to be_nil
      end
    end
  end
end
