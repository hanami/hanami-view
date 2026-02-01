# frozen_string_literal: true

RSpec.describe "Scopes" do
  let(:base_view) {
    Class.new(Hanami::View) do
      config.paths = FIXTURES_PATH.join("integration/scopes")
    end
  }

  describe "Custom scope for a view" do
    it "renders the template using the scope" do
      custom_scope = Class.new(Hanami::View::Scope) do
        def hello
          "Hello #{locals[:text]}!"
        end
      end

      view = Class.new(base_view) do
        config.template = "custom_view_scope"
        config.scope = custom_scope

        expose :text
      end.new

      expect(view.(text: "world").to_s).to eq "Hello world!"
    end
  end

  describe "inline scope class" do
    context "scope_class not configured" do
      it "renders the template using the scope" do
        view = Class.new(base_view) do
          config.template = "custom_view_scope"

          expose :text

          scope do
            def hello
              "Hello #{locals[:text]}!"
            end
          end
        end.new

        expect(view.(text: "world").to_s).to eq "Hello world!"
      end
    end

    context "scope_class configured" do
      it "creates a scope subclass inheriting from the scope_class and renders the template using the scope subclass" do
        scope_class = Class.new(Hanami::View::Scope) {
          private

          def exclaim(str)
            "#{str}!"
          end
        }

        view = Class.new(base_view) do
          config.template = "custom_view_scope"
          config.scope_class = scope_class

          expose :text

          scope do
            def hello
              exclaim("Hello #{locals[:text]}")
            end
          end
        end.new

        expect(view.(text: "world").to_s).to eq "Hello world!"
      end
    end

    context "scope configured" do
      it "creates a scope subclass inheriting from the configured scope and renders the template using the scope subclass" do
        scope_class = Class.new(Hanami::View::Scope) {
          private

          def exclaim(str)
            "#{str}!"
          end
        }

        view = Class.new(base_view) do
          config.template = "custom_view_scope"
          config.scope = scope_class

          expose :text

          scope do
            def hello
              exclaim("Hello #{locals[:text]}")
            end
          end
        end.new

        expect(view.(text: "world").to_s).to eq "Hello world!"
      end
    end

    context "both scope_class and scope configured" do
      it "creates a scope subclass from the configured scope (ignoring scope_class) and renders the template using the scope subclass" do
        base_scope_class = Class.new(Hanami::View::Scope) {
          private

          def exclaim(str)
            "NOT USED"
          end
        }

        view_scope_class = Class.new(Hanami::View::Scope) {
          private

          def exclaim(str)
            "#{str}!"
          end
        }

        view = Class.new(base_view) do
          config.template = "custom_view_scope"
          config.scope_class = base_scope_class
          config.scope = view_scope_class

          expose :text

          scope do
            def hello
              exclaim("Hello #{locals[:text]}")
            end
          end
        end.new

        expect(view.(text: "world").to_s).to eq "Hello world!"
      end
    end
  end

  specify "Rendering a partial via an anonymous scope" do
    view = Class.new(base_view) do
      config.template = "anonymous_scope"

      expose :text
    end.new

    expect(view.(text: "Hello").to_s).to eq "Greeting: Hello"
  end

  specify "Rendering a partial implicitly via a custom named scope" do
    module Test::Scopes
      class Greeting < Hanami::View::Scope
        def greeting
          _locals[:greeting].upcase + "!"
        end
      end
    end

    view = Class.new(base_view) do
      config.scope_namespace = Test::Scopes
      config.template = "named_scope_with_implicit_render"

      expose :text
    end.new

    expect(view.(text: "Hello").to_s).to eq "Greeting: HELLO!"
  end

  specify "Rendering a partial implicitly via a custom named scope (provided via a class)" do
    module Test::Scopes
      class Greeting < Hanami::View::Scope
        def greeting
          _locals[:greeting].upcase + "!"
        end
      end
    end

    view = Class.new(base_view) do
      config.scope_namespace = Test::Scopes
      config.template = "class_named_scope_with_implicit_render"

      expose :text
    end.new

    expect(view.(text: "Hello").to_s).to eq "Greeting: HELLO!"
  end

  specify "Raising an error when an unnamed partial cannot be rendered implicitly" do
    view = Class.new(base_view) do
      config.template = "unnamed_named_scope_with_implicit_render"
    end.new

    expect { view.().to_s }.to raise_error ArgumentError, "+partial_name+ must be provided for unnamed scopes"
  end

  specify "Rendering a partial explicitly via a custom named scope" do
    module Test::Scopes
      class Greeting < Hanami::View::Scope
        def greeting
          _locals[:greeting].upcase + "!"
        end
      end
    end

    view = Class.new(base_view) do
      config.scope_namespace = Test::Scopes
      config.template = "named_scope_with_explicit_render"

      expose :text
    end.new

    expect(view.(text: "Hello").to_s).to eq "Holler: HELLO!"
  end

  specify "Custom named scope providing defaults for missing locals" do
    module Test::Scopes
      class Greeting < Hanami::View::Scope
        def greeting
          _locals.fetch(:greeting, "Howdy")
        end
      end
    end

    view = Class.new(base_view) do
      config.scope_namespace = Test::Scopes
      config.template = "named_scope_with_defaults"

      expose :text
    end.new

    expect(view.().to_s).to eq "Greeting: Howdy"
  end

  specify "Creating a custom scope from a view part" do
    module Test::Parts
      class Message < Hanami::View::Part
        def greeting
          # FIXME: partial name should not be required here
          scope(:greeting, greeting: value[:text]).render("shared/greeting")
        end
      end
    end

    module Test::Scopes
      class Greeting < Hanami::View::Scope
        def greeting
          _locals[:greeting] + "!"
        end
      end
    end

    view = Class.new(base_view) do
      config.part_namespace = Test::Parts
      config.scope_namespace = Test::Scopes
      config.template = "scope_from_part"

      expose :message
    end.new

    expect(view.(message: {text: "Hello from a part"}).to_s).to eq "Greeting: Hello from a part!"
  end

  specify "Creating a custom anonymous scope" do
    view = Class.new(base_view) do
      config.template = "custom_anonymous_scope"
      expose :message

      scope do
        def greeting
          shout(_locals[:message])
        end

        def shout(string)
          string.upcase + "!"
        end

        def year(time)
          time.year.to_s
        end
      end
    end.new

    message = "Hello"
    rendered = view.(message: message).to_s
    expect(rendered).to include(message.upcase + "!")
    expect(rendered).to include(Time.now.utc.year.to_s)
  end

  specify "Creating a custom anonymous scope that inherits from application scope" do
    module Test
      module Helpers
        module StringFormattingHelpers
          private

          def upcase(string)
            string.upcase
          end
        end

        module TimeFormattingHelpers
          private

          def year(time)
            time.year.to_s
          end
        end
      end

      module Scopes
        class ApplicationScope < Hanami::View::Scope
          include Test::Helpers::StringFormattingHelpers
          include Test::Helpers::TimeFormattingHelpers
        end
      end
    end

    ApplicationView = Class.new(base_view) do
      config.scope = Test::Scopes::ApplicationScope
    end

    view = Class.new(ApplicationView) do
      config.template = "custom_anonymous_scope"
      expose :message

      scope do
        def greeting
          shout(_locals[:message])
        end

        def shout(string)
          upcase(string) + "!"
        end
      end
    end.new

    message = "Hello"
    rendered = view.(message: message).to_s
    expect(rendered).to include(message.upcase + "!")
    expect(rendered).to include(Time.now.utc.year.to_s)
  end
end
