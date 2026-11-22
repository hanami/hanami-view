# frozen_string_literal: true

require_relative "support/isolation_spec_helper"

IsolationSpecHelper.require_libraries "hanami/view", "active_support", "active_support/core_ext/string/output_safety"

require_relative "support/active_support_examples"

RSpec.describe "With Active Support loaded after Hanami View" do
  include_examples "Active Support compatibility"
end

RSpec::Core::Runner.autorun
