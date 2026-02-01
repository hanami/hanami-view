# frozen_string_literal: true

RSpec.describe "Template rendering / locals" do
  let(:base_view) {
    Class.new(Hanami::View) do
      config.paths = FIXTURES_PATH.join("integration/template_rendering/locals")
    end
  }

  specify "Accessing all `locals` inside template" do
    view = Class.new(base_view) do
      config.template = "locals_in_template"

      expose :text, decorate: false
    end.new

    if RUBY_VERSION < "3.4"
      expect(view.call(text: "Hello").to_s).to eq %(Locals: {:text=>"Hello"})
    else
      expect(view.call(text: "Hello").to_s).to eq %(Locals: {text: "Hello"})
    end
  end
end
