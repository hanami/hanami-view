# frozen_string_literal: true

RSpec.describe "View / locals" do
  specify "locals are not decorated by default" do
    view = Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "greeting"

      expose :greeting
    end.new

    local = view.(greeting: "Hello").locals[:greeting]

    expect(local).to eq "Hello"
  end

  specify "locals are decorated if their exposure is marked as `decorate: true`" do
    view = Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "greeting"

      expose :greeting, decorate: true
    end.new

    local = view.(greeting: "Hello").locals[:greeting]

    expect(local).to be_a(Hanami::View::Part)
  end

  specify "locals can be decorated using the `decorate` method" do
    view = Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "greeting"

      decorate :greeting
    end.new

    local = view.(greeting: "Hello").locals[:greeting]

    expect(local).to be_a(Hanami::View::Part)
  end

  specify "`decorate` method works with blocks" do
    view = Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "greeting"

      decorate :greeting do |greeting:|
        greeting.upcase
      end
    end.new

    local = view.(greeting: "Hello").locals[:greeting]

    expect(local).to be_a(Hanami::View::Part)
    expect(local.value).to eq "HELLO"
  end

  specify "`decorate` method works with multiple exposures" do
    view = Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "greeting"

      decorate :greeting, :message
    end.new

    result = view.(greeting: "Hello", message: "World")

    expect(result.locals[:greeting]).to be_a(Hanami::View::Part)
    expect(result.locals[:message]).to be_a(Hanami::View::Part)
  end

  specify "`decorate` method supports :as option" do
    module Test
      class CustomPart < Hanami::View::Part
        def custom_method
          "Custom: #{value}"
        end
      end
    end

    view = Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "greeting"

      decorate :greeting, as: Test::CustomPart
    end.new

    local = view.(greeting: "Hello").locals[:greeting]

    expect(local).to be_a(Test::CustomPart)
    expect(local.custom_method).to eq "Custom: Hello"
  end

  specify "locals are decorated by default when config.decorate_exposures is true" do
    view = Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "greeting"
      config.decorate_exposures = true

      expose :greeting
    end.new

    local = view.(greeting: "Hello").locals[:greeting]

    expect(local).to be_a(Hanami::View::Part)
  end

  specify "locals are not decorated when config.decorate_exposures is true but exposure has decorate: false" do
    view = Class.new(Hanami::View) do
      config.paths = SPEC_ROOT.join("fixtures/templates")
      config.template = "greeting"
      config.decorate_exposures = true

      expose :greeting, decorate: false
    end.new

    local = view.(greeting: "Hello").locals[:greeting]

    expect(local).to eq "Hello"
  end
end
