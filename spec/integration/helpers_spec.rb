# frozen_string_literal: true

RSpec.describe "helpers" do
  let(:dir) { make_tmp_directory }

  describe "in templates" do
    before do
      with_directory(dir) do
        write "template.html.erb", <<~ERB
          <%= format_number(number) %>
        ERB
      end
    end

    let(:view) {
      dir = self.dir
      scope_class = self.scope_class

      Class.new(Hanami::View) do
        config.paths = dir
        config.template = "template"
        config.scope_class = scope_class

        expose :number
      end.new
    }

    let(:scope_class) {
      Class.new(Hanami::View::Scope) {
        include Hanami::View::Helpers::NumberFormattingHelper
      }
    }

    specify do
      expect(view.(number: 12_300).to_s.strip).to eq "12,300"
    end
  end

  describe "in parts" do
    before do
      with_directory(dir) do
        write "template.html.erb", <<~ERB
          <%= city.population_text %>
        ERB
      end
    end

    let(:part_class) {
      Class.new(Hanami::View::Part) {
        include Hanami::View::Helpers::NumberFormattingHelper

        def population_text
          format_number(population)
        end
      }
    }

    let(:view) {
      dir = self.dir
      part_class = self.part_class

      Class.new(Hanami::View) {
        config.paths = dir
        config.template = "template"

        expose :city, as: part_class
      }.new
    }

    specify do
      canberra = Struct.new(:population).new(463_000)

      expect(view.(city: canberra).to_s.strip).to eq "463,000"
    end
  end
end
