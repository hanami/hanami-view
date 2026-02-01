# frozen_string_literal: true

RSpec.describe Hanami::View::Context do
  let(:rendering) {
    Class.new(Hanami::View) {
      config.paths = FIXTURES_PATH
      config.template = "_"
    }.new.rendering(format: :html)
  }

  describe "#dup_for_rendering" do
    let(:context_class) {
      Class.new(Hanami::View::Context) {
        attr_reader :injected_obj, :internal_var

        def initialize(injected_obj:)
          super()
          @injected_obj = injected_obj
          @internal_var = "internal"
        end
      }
    }

    let(:injected_obj) { Struct.new(:foo).new }

    it "copies all state" do
      context = context_class.new(injected_obj: injected_obj)
      context.instance_variable_set(:@internal_var, "updated internal")

      new_context = context.dup_for_rendering(rendering)

      expect(new_context._rendering).to be rendering
      expect(new_context.injected_obj).to be injected_obj
      expect(new_context.internal_var).to eq "updated internal"
    end
  end

  describe "decorated attributes" do
    subject(:context) { context_class.new(assets: assets) }

    let(:context_class) {
      Class.new(Hanami::View::Context) {
        attr_reader :assets

        decorate :assets

        def initialize(assets:)
          super()
          @assets = assets
        end
      }
    }

    let(:assets) { Struct.new(:manifests).new }

    context "without rendering" do
      it "raises a RenderingMissingError" do
        expect { context.assets }.to raise_error(Hanami::View::RenderingMissingError)
      end
    end

    context "with rendering" do
      subject(:context) { context_class.new(assets: assets).dup_for_rendering(rendering) }

      describe "attribute readers" do
        it "provides attributes decorated in view parts" do
          expect(context.assets).to be_a Hanami::View::Part
          expect(context.assets.value).to eq assets
        end
      end
    end
  end
end
