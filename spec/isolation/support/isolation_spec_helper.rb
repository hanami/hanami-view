# frozen_string_literal: true

# Helper for isolation specs. Each isolation spec runs in its own Ruby process (see the
# `spec:isolation` Rake task), so it can load libraries in a specific order, or change global state,
# without affecting other specs.

if defined?(Hanami::View)
  abort "Hanami View is already loaded, so this isolation spec cannot control its load order. " \
        "Run it with `bundle exec rake spec:isolation` or `ruby spec/isolation/<file>_spec.rb`."
end

require "rubygems"
require "bundler"
Bundler.setup(:default, :development, :test)

$LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)

require "rspec"
require_relative "../../support/rspec"

module IsolationSpecHelper
  @load_warnings = []

  class << self
    # Warnings emitted while loading libraries via {.require_libraries}.
    attr_reader :load_warnings
  end

  module CaptureWarnings
    def warn(message, ...)
      IsolationSpecHelper.load_warnings << message
      super
    end
  end

  Warning.singleton_class.prepend(CaptureWarnings)

  # Requires the given libraries in order, with Ruby warnings enabled, and captures any warnings in
  # {.load_warnings}.
  def self.require_libraries(*libraries)
    verbose = $VERBOSE
    $VERBOSE = true
    libraries.each { require _1 }
  ensure
    $VERBOSE = verbose
  end
end
