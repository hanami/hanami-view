# frozen_string_literal: true

begin
  require "pry-byebug"
rescue LoadError; end
SPEC_ROOT = Pathname(__FILE__).dirname
FIXTURES_PATH = SPEC_ROOT.join("fixtures")

require "slim"
require "hanami/view"

require_relative "support/tmp_directory"

module TestNamespace
  def remove_constants
    constants.each(&method(:remove_const))
  end
end

module Test
  extend TestNamespace
end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed

  config.after do
    Test.remove_constants
  end

  config.after do
    Hanami::View.cache.clear
  end
end

RSpec::Matchers.define :part_including do |data|
  match { |actual|
    data.all? { |(key, val)|
      actual._data[key] == val
    }
  }
end
