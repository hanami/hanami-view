# frozen_string_literal: true

RSpec.describe "scope builder" do
  describe "default scope builder" do
    it "defaults to creating instances of Hanami::View::Scope" do
      view = Class.new(Hanami::View) do
        config.paths = SPEC_ROOT.join("__ignore__")
        config.template = "__ignore__"
      end.new

      scope = view.rendering.scope({})

      expect(scope).to be_an_instance_of Hanami::View::Scope
    end

    it "create instances of a configured scope_class" do
      scope_class = Class.new(Hanami::View::Scope)

      view = Class.new(Hanami::View) do
        config.paths = SPEC_ROOT.join("__ignore__")
        config.template = "__ignore__"

        config.scope_class = scope_class
      end.new

      scope = view.rendering.scope({})

      expect(scope).to be_an_instance_of scope_class
    end

    describe "named scopes" do
      let(:namespace) { Module.new }
      let(:scope_one) { Class.new(Hanami::View::Scope) }
      let(:scope_two) { Class.new(Hanami::View::Scope) }

      before do
        stub_const "TestScopes", namespace
        stub_const "TestScopes::ScopeOne", scope_one
        stub_const "TestScopes::ScopeTwo", scope_two
      end

      it "creates instances of the scopes by name" do
        view = Class.new(Hanami::View) {
          config.scope_namespace = TestScopes

          config.paths = SPEC_ROOT.join("__ignore__")
          config.template = "__ignore__"
        }.new

        scope = view.rendering.scope("scope_one", {})
        expect(scope).to be_an_instance_of TestScopes::ScopeOne

        scope = view.rendering.scope("scope_two", {})
        expect(scope).to be_an_instance_of TestScopes::ScopeTwo
      end
    end

    describe "without a scope_namespace" do
      let(:view) {
        Class.new(Hanami::View) {
          config.paths = SPEC_ROOT.join("__ignore__")
          config.template = "__ignore__"
        }.new
      }

      it "raises an error naming the scope it cannot find" do
        expect { view.rendering.scope("sidebar", {}) }.to raise_error(
          Hanami::View::UndefinedConfigError,
          'no +scope_namespace+ configured; needed to find scope "sidebar"; ' \
          "set it, or pass the scope class itself"
        )
      end

      it "builds an unnamed scope" do
        expect(view.rendering.scope({})).to be_an_instance_of Hanami::View::Scope
      end

      it "builds a scope from a given class" do
        scope_class = Class.new(Hanami::View::Scope)

        expect(view.rendering.scope(scope_class, {})).to be_an_instance_of scope_class
      end
    end
  end
end
