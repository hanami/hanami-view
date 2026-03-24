# frozen_string_literal: true

RSpec.describe "part builder" do
  before do
    module Test
      class Custom < Hanami::View::Part
        def to_s
          "Custom part wrapping #{_value}"
        end
      end

      CustomPart = Custom

      class CustomArrayPart < Hanami::View::Part
        def each(&block)
          (_value * 2).each(&block)
        end
      end
    end
  end

  describe "default part builder" do
    it "defaults to creating instances of Hanami::View::Part" do
      view = Class.new(Hanami::View) do
        config.paths = SPEC_ROOT.join("__ignore__")
        config.template = "__ignore__"
      end.new

      part = view.rendering.part(:my_part, Object.new)

      expect(part).to be_an_instance_of Hanami::View::Part
    end

    it "create instances of a configured part_class" do
      part_class = Class.new(Hanami::View::Part)

      view = Class.new(Hanami::View) do
        config.paths = SPEC_ROOT.join("__ignore__")
        config.template = "__ignore__"

        config.part_class = part_class
      end.new

      part = view.rendering.part(:my_part, Object.new)

      expect(part).to be_an_instance_of part_class
    end

    it "looks up classes from a part namespace" do
      view = Class.new(Hanami::View) do
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.layout = nil
        config.template = "decorated_parts"
        config.part_namespace = Test

        expose :customs, decorate: true
        expose :custom, decorate: true
        expose :ordinary
      end.new

      expect(view.(customs: ["many things"], custom: "custom thing", ordinary: "ordinary thing").to_s).to eql(
        "<p>Custom part wrapping many things</p><p>Custom part wrapping custom thing</p><p>ordinary thing</p>"
      )
    end

    it "wraps array members in custom part classes provided to exposure :as option" do
      view = Class.new(Hanami::View) do
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.layout = nil
        config.template = "decorated_parts"

        expose :customs, as: Test::CustomPart, decorate: true
        expose :custom, as: Test::CustomPart, decorate: true
        expose :ordinary
      end.new

      expect(view.(customs: ["many things"], custom: "custom thing", ordinary: "ordinary thing").to_s).to eql(
        "<p>Custom part wrapping many things</p><p>Custom part wrapping custom thing</p><p>ordinary thing</p>"
      )
    end

    it "wraps an array and its members in custom part classes provided to exposure :as option as an array" do
      view = Class.new(Hanami::View) do
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.layout = nil
        config.template = "decorated_parts"

        expose :customs, as: [Test::CustomArrayPart, Test::CustomPart], decorate: true
        expose :custom, as: Test::CustomPart, decorate: true
        expose :ordinary
      end.new

      expect(view.(customs: ["many things"], custom: "custom thing", ordinary: "ordinary thing").to_s).to eql(
        "<p>Custom part wrapping many things</p><p>Custom part wrapping many things</p><p>Custom part wrapping custom thing</p><p>ordinary thing</p>"
      )
    end
  end

  describe "custom part builder and part classes" do
    it "supports wrapping in custom parts based on exposure names" do
      part_builder = Class.new(Hanami::View::PartBuilder) do
        class << self
          def part_class(name:, **options)
            name == :custom ? Test::CustomPart : super
          end
        end
      end

      view = Class.new(Hanami::View) do
        config.part_builder = part_builder
        config.paths = SPEC_ROOT.join("fixtures/templates")
        config.layout = nil
        config.template = "decorated_parts"

        expose :customs, :custom, decorate: true
        expose :ordinary
      end.new

      expect(view.(customs: ["many things"], custom: "custom thing", ordinary: "ordinary thing").to_s).to eql(
        "<p>Custom part wrapping many things</p><p>Custom part wrapping custom thing</p><p>ordinary thing</p>"
      )
    end
  end
end
