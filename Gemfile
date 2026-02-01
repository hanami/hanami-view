# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

group :tools do
  # Remove hotch until https://github.com/ko1/allocation_tracer/issues/19 is fixed and it can be
  # installed on macOS again.
  # gem "hotch"
end

group :test do
  gem "rspec"
  gem "saharspec"

  gem "dry-inflector"
  gem "dry-files"
  gem "erubi"
  gem "haml", "~> 6.0"
  gem "hanami-cli", github: "hanami/cli", branch: "main"
  gem "hanami", github: "hanami/hanami", branch: "main"
  gem "hanami-utils", github: "hanami/utils", branch: "main"
  gem "hanami-controller", github: "hanami/controller", branch: "main"
  gem "hanami-router", github: "hanami/router", branch: "main"
  gem "hanami-devtools", github: "hanami/devtools", branch: "main"
  gem "rack", ">= 2.0.6"
  gem "slim", "~> 5.0"
end

group :benchmarks do
  gem "actionpack"
  gem "actionview"
  gem "benchmark-ips"
end

group :docs do
  gem "redcarpet", platforms: :mri
  gem "yard"
  gem "yard-junk"
end
