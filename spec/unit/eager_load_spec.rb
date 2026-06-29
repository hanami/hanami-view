# frozen_string_literal: true

RSpec.describe Hanami::View, "eager loading" do
  it "can be eager loaded even when the optional haml and slim gems are unavailable" do
    # Simulate the haml and slim gems not being installed. The adapters that require them are loaded
    # lazily by Tilt (see `Hanami::View::Tilt`) only when their template engines are used, so eager
    # loading must not attempt to load them.
    allow_any_instance_of(Object).to receive(:require).and_wrap_original do |original, name, *args|
      if %w[haml slim].include?(name)
        raise LoadError, "cannot load such file -- #{name}"
      end

      original.call(name, *args)
    end

    expect { Hanami::View.gem_loader.eager_load(force: true) }.not_to raise_error
  end
end
