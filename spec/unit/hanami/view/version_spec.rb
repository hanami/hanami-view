# frozen_string_literal: true

RSpec.describe "Hanami::View::VERSION" do
  it "exposes version" do
    expect(Hanami::View::VERSION).to eq("1.3.1")
  end
end
