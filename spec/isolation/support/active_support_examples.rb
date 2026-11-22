# frozen_string_literal: true

require "dry/inflector"

RSpec.shared_examples "Active Support compatibility" do
  it "uses Active Support's String#html_safe" do
    expect("x".html_safe).to be_an_instance_of(ActiveSupport::SafeBuffer)
  end

  it "keeps html_safe? for objects and numbers" do
    expect(Object.new).not_to be_html_safe
    expect(1).to be_html_safe
  end

  it "does not cause method redefinition warnings" do
    redefinition_warnings = IsolationSpecHelper.load_warnings.grep(/method redefined; discarding old html_safe/)

    expect(redefinition_warnings).to be_empty
  end

  it "renders views with correct escaping" do
    view = Class.new(Hanami::View) {
      config.paths = File.join(__dir__, "../fixtures/templates")
      config.template = "active_support"
      config.scope_class = Class.new(Hanami::View::Scope) {
        include Hanami::View::Helpers::TagHelper
      }
      config.default_context = Class.new(Hanami::View::Context) {
        def inflector = Dry::Inflector.new
      }.new

      expose :unsafe, :safe
    }.new

    output = view.(unsafe: "<x>", safe: "<y>".html_safe).to_s

    expect(output).to eq <<~HTML
      &lt;x&gt;
      <y>
      <p>&lt;x&gt;</p>
      <div><b>captured</b> &lt;x&gt;</div>
    HTML
  end
end
