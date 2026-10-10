# frozen_string_literal: true

RSpec.describe "Scopes / declared locals" do
  let(:base_view) {
    Class.new(Hanami::View) do
      config.paths = FIXTURES_PATH.join("integration/scope_locals")
      config.scope_namespace = Test::Scopes
    end
  }

  let(:view) {
    Class.new(base_view) do
      config.template = "named"

      expose :scope_locals, decorate: false
    end.new
  }

  before do
    module Test::Scopes
      class Greeting < Hanami::View::Scope
        locals :name, greeting: "Hello"

        def message = "#{greeting}, #{name}!"

        def echo = render("shared/echo", word: "Kia ora")
      end
    end
  end

  it "renders with the locals given, filling in defaults for the rest" do
    expect(view.(scope_locals: {name: "Jane"}).to_s.strip).to eq "Hello, Jane!"
    expect(view.(scope_locals: {name: "Jane", greeting: "Kia ora"}).to_s.strip).to eq "Kia ora, Jane!"
  end

  it "raises for a missing local, naming the scope" do
    expect { view.(scope_locals: {greeting: "Kia ora"}) }
      .to raise_error(ArgumentError, "missing local: :name for Test::Scopes::Greeting")
  end

  it "raises for an unknown local" do
    expect { view.(scope_locals: {name: "Jane", nmae: "Jane", title: "Dr"}) }
      .to raise_error(ArgumentError, "unknown locals: :nmae, :title for Test::Scopes::Greeting")
  end

  it "applies to subclasses, which may replace the declaration" do
    module Test::Scopes
      class Formal < Greeting
      end

      class Casual < Greeting
        locals :name

        def message = "Hey #{name}"
      end
    end

    expect { Test::Scopes::Formal._declared_locals({}) }
      .to raise_error(ArgumentError, "missing local: :name for Test::Scopes::Formal")
    expect(Test::Scopes::Casual._declared_locals({name: "Jane"})).to eq(name: "Jane")
  end

  it "raises for a class declaring its locals twice" do
    expect { Test::Scopes::Greeting.locals :name }
      .to raise_error(ArgumentError, "locals already declared for Test::Scopes::Greeting")
  end

  it "takes locals keyed by String as Symbols" do
    expect(Test::Scopes::Greeting._declared_locals({"name" => "Jane"})).to eq(greeting: "Hello", name: "Jane")
  end

  it "does not check the locals of partials the scope renders" do
    view = Class.new(base_view) { config.template = "echo" }.new

    expect(view.().to_s.strip).to eq "Kia ora"
  end

  it "checks a scope built from a part, which is given the part under its name" do
    module Test::Parts
      class Person < Hanami::View::Part
        def greeting = scope(:greeting, name: value[:name]).render("shared/greeting")
      end
    end

    view = Class.new(base_view) do
      config.part_namespace = Test::Parts
      config.template = "from_part"

      expose :person, decorate: true
    end.new

    expect { view.(person: {name: "Jane"}) }.to raise_error(ArgumentError, "unknown local: :person for Test::Scopes::Greeting")

    Test::Scopes::Greeting.remove_instance_variable(:@_locals_declaration)
    Test::Scopes::Greeting.locals :name, :person, greeting: "Hello"

    expect(view.(person: {name: "Jane"}).to_s.strip).to eq "Hello, Jane!"

    part = Test::Parts::Person.new(value: {name: "Jane"}, rendering: view.rendering)
    expect(part._scope(:greeting, name: "Jane")._locals).to include(person: part)
  end

  it "leaves a scope without a declaration unchecked" do
    module Test::Scopes
      class Greeting
        remove_instance_variable(:@_locals_declaration)
      end
    end

    expect(view.(scope_locals: {name: "Jane", greeting: "Hi", extra: 1}).to_s.strip).to eq "Hi, Jane!"
  end
end
