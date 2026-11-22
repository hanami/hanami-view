# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

# Isolation specs are excluded from this task via `.rspec`, and run via `spec:isolation` instead.
RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "Run isolation tests"
  task :isolation do
    # Run each isolation test in its own Ruby process, using with_unbundled_env to ensure bundler
    # doesn't load extra gems.
    Dir["spec/isolation/**/*_spec.rb"].each do |test_file|
      puts "\n\nRunning: #{test_file}"
      Bundler.with_unbundled_env do
        system(Gem.ruby, test_file, "--options", "spec/isolation/.rspec") ||
          abort("Isolation test failed: #{test_file}")
      end
    end
  end
end

desc "Run all tests"
task test: ["spec", "spec:isolation"]

RuboCop::RakeTask.new(:rubocop)

desc "Run all linters"
task lint: :rubocop

task default: %i[lint test]
