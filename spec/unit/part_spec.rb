# frozen_string_literal: true

RSpec::Matchers.define :scope_including do |locals|
  match do |actual|
    locals == actual._locals
  end
end

RSpec.describe Hanami::View::Part do
  let(:name) { :user }
  let(:value) { double(:value) }
  let(:rendering) {
    view.rendering(format: :html).tap do |rendering|
      allow(rendering).to receive(:partial)
    end
  }
  let(:view) {
    Class.new(Hanami::View) {
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "hello"
    }.new
  }

  context "with a rendering" do
    subject(:part) {
      described_class.new(name: name, value: value, rendering: rendering)
    }

    describe "#render" do
      it "renders a partial with the part available in its scope" do
        part.render("info")
        expect(rendering).to have_received(:partial).with("info", scope_including(user: part))
      end

      it "allows the part to be made available on a different name" do
        part.render("info", as: :admin)
        expect(rendering).to have_received(:partial).with("info", scope_including(admin: part))
      end

      it "includes extra locals in the scope" do
        part.render("info", extra_local: "hello")
        expect(rendering).to have_received(:partial).with("info", scope_including(user: part, extra_local: "hello"))
      end
    end

    describe "#to_s" do
      before do
        allow(value).to receive(:to_s).and_return "to_s on the value"
      end

      it "delegates to the wrapped value" do
        expect(part.to_s).to eq "to_s on the value"
      end
    end

    describe "#new" do
      it "preserves rendering" do
        new_part = part.new(value: "new value")
        expect(new_part._rendering).to be part._rendering
      end
    end

    describe "#inspect" do
      it "includes the class name, name, and value only" do
        expect(part.inspect).to eq "#<Hanami::View::Part name=:user value=#<Double :value>>"
      end
    end

    describe "#_format" do
      before do
        allow(rendering).to receive(:format) { :xml }
      end

      it "returns the rendering's format" do
        expect(part._format).to eq :xml
      end
    end

    describe "#method_missing" do
      let(:value) { double(greeting: "hello from value") }

      it "calls a matching method on the value" do
        expect(part.greeting).to eq "hello from value"
      end

      it "forwards all arguments to the method" do
        blk = -> {}
        part.greeting "args", &blk

        expect(value).to have_received(:greeting).with("args", &blk)
      end

      it "raises an error if no method matches" do
        expect { part.farewell }.to raise_error(NoMethodError)
      end
    end

    describe "#respond_to?" do
      let(:value) { double(greeting: "hello from value") }

      it "handles convenience methods" do
        expect(part).to respond_to(:format)
        expect(part).to respond_to(:context)
        expect(part).to respond_to(:render)
        expect(part).to respond_to(:scope)
        expect(part).to respond_to(:value)
      end

      it "handles value methods" do
        expect(part).to respond_to(:greeting)
      end
    end
  end

  context "without a rendering" do
    subject(:part) {
      described_class.new(
        name: name,
        value: value
      )
    }

    describe "#format" do
      it "raises an error" do
        expect { part.render("info") }.to raise_error(Hanami::View::RenderingMissingError)
      end
    end

    describe "#render" do
      it "raises an error" do
        expect { part.render("info") }.to raise_error(Hanami::View::RenderingMissingError)
      end
    end

    describe "#scope" do
      it "raises an error" do
        expect { part.scope("info") }.to raise_error(Hanami::View::RenderingMissingError)
      end
    end
  end

  context "without a name provided" do
    describe "#_name" do
      context "when class has a name" do
        before do
          Test::MyPart = Class.new(Hanami::View::Part)
        end

        subject(:part) {
          Test::MyPart.new(value: value)
        }

        it "is inferred from the class name" do
          expect(part._name).to eq :my_part
        end

        it "makes the part available to partials under its name" do
          described_part = Test::MyPart.new(value: value, rendering: rendering)
          described_part.render("info")
          expect(rendering).to have_received(:partial).with("info", scope_including(my_part: described_part))
        end
      end

      context "when class is anonymous" do
        subject(:part) {
          Class.new(Hanami::View::Part).new(value: value)
        }

        it "defaults to :part" do
          expect(part._name).to eq :part
        end
      end
    end
  end
end
