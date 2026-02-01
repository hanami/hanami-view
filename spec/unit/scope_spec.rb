# frozen_string_literal: true

RSpec.describe Hanami::View::Scope do
  let(:locals) { {} }

  context "with a rendering" do
    subject(:scope) { described_class.new(locals: locals, rendering: rendering) }

    let(:rendering) { view.rendering(format: :html) }
    let(:view) {
      Class.new(Hanami::View) {
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.template = "hello"
      }.new
    }

    let(:context) { double(:context) }

    before do
      allow(rendering).to receive(:partial) { "" }
      allow(rendering).to receive(:context) { context }
    end

    describe "#render" do
      it "renders a partial with itself as the scope" do
        scope.render("info")
        expect(rendering).to have_received(:partial).with("info", scope)
      end

      it "renders a partial with provided locals" do
        scope_with_locals = described_class.new(
          locals: {foo: "bar"},
          rendering: rendering
        )

        scope.render("info", foo: "bar")

        expect(rendering).to have_received(:partial).with("info", scope_with_locals)
      end
    end

    describe "#_format" do
      let(:rendering) { view.rendering(format: :xml) }

      it "returns the rendering's format" do
        expect(scope._format).to eq :xml
      end
    end

    describe "#_context" do
      it "returns the renderings's context" do
        expect(scope._context).to be context
      end
    end

    describe "#method_missing" do
      describe "matching locals" do
        let(:locals) { {greeting: "hello from locals"} }
        let(:context) { double(:context, greeting: "hello from context") }

        it "returns a matching value from the locals, in favour of a matching method on the context" do
          expect(scope.greeting).to eq "hello from locals"
        end
      end

      describe "matching context" do
        let(:context) { double(:context, greeting: "hello from context") }

        it "calls the matching method on the context" do
          expect(scope.greeting).to eq "hello from context"
        end

        it "forwards all arguments to the method" do
          blk = -> {}
          scope.greeting "args", &blk

          expect(context).to have_received(:greeting).with("args", &blk)
        end
      end

      describe "matching convenience methods" do
        it "provides #context" do
          expect(scope.context).to be context
        end

        it "provides #locals" do
          expect(scope.locals).to be locals
        end
      end

      describe "no matches" do
        it "raises an error" do
          expect { scope.greeting }.to raise_error(NoMethodError)
        end
      end
    end
  end

  context "without a rendering" do
    subject(:scope) {
      described_class.new(locals: locals)
    }

    describe "#render" do
      it "raises an error" do
        expect { scope.render(:info) }.to raise_error(Hanami::View::RenderingMissingError)
      end
    end

    describe "#scope" do
      it "raises an error" do
        expect { scope.scope(:info) }.to raise_error(Hanami::View::RenderingMissingError)
      end
    end

    describe "#_context" do
      it "raises an error" do
        expect { scope._context }.to raise_error(Hanami::View::RenderingMissingError)
      end
    end
  end
end
