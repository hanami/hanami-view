# frozen_string_literal: true

RSpec.describe Hanami::View::Tilt do
  subject(:tilt) { described_class }

  let(:erb_template) { fixture("templates/users.txt.erb") }
  let(:html_erb_template) { fixture("templates/utf8.html.erb") }
  let(:haml_template) { fixture("integration/template_engines/haml/escaping.html.haml") }
  let(:slim_template) { fixture("templates/hello.html.slim") }

  def fixture(path)
    SPEC_ROOT.join("fixtures", path).to_s
  end

  describe ".[]" do
    it "uses our own ERB template for .erb templates" do
      expect(tilt[erb_template, {}, {}]).to be_an_instance_of Hanami::View::ERB::Template
    end

    # Tilt registers "html.erb" as an extension of its own, and matches the longest registered
    # extension first, so without our own handling these templates would bypass our ERB engine.
    it "uses our own ERB template for .html.erb templates" do
      expect(tilt[html_erb_template, {}, {}]).to be_an_instance_of Hanami::View::ERB::Template
    end

    it "uses our own adapter template for .haml templates" do
      expect(tilt[haml_template, {}, {}]).to be_an_instance_of Hanami::View::Tilt::HamlAdapter::Template
    end

    it "uses our own adapter template for .slim templates" do
      expect(tilt[slim_template, {}, {}]).to be_an_instance_of Hanami::View::Tilt::SlimAdapter::Template
    end

    it "honours engine mappings given for the erb extension, including for .html.erb templates" do
      mapping = {erb: Tilt::ErubiTemplate}

      expect(tilt[erb_template, mapping, {}]).to be_an_instance_of Tilt::ErubiTemplate
      expect(tilt[html_erb_template, mapping, {}]).to be_an_instance_of Tilt::ErubiTemplate
    end

    it "honours engine mappings given for other extensions" do
      mapping = {slim: Tilt::PlainTemplate}

      expect(tilt[slim_template, mapping, {}]).to be_an_instance_of Tilt::PlainTemplate
    end
  end
end
