# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/view/version'

Gem::Specification.new do |spec|
  spec.name          = 'hanami-view'
  spec.authors       = ["Tim Riley", "Piotr Solnica"]
  spec.email         = ["tim@icelab.com.au", "piotr.solnica@gmail.com"]
  spec.license       = 'MIT'
  spec.version       = Hanami::View::VERSION.dup

  spec.summary       = "A complete, standalone view rendering system that gives you everything you need to write well-factored view code"
  spec.description   = spec.summary
  spec.homepage      = 'https://dry-rb.org/gems/hanami-view'
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "hanami-view.gemspec", "lib/**/*"]
  spec.bindir        = 'bin'
  spec.executables   = []
  spec.require_paths = ['lib']
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['changelog_uri']     = 'https://github.com/hanami/view/blob/main/CHANGELOG.md'
  spec.metadata['source_code_uri']   = 'https://github.com/hanami/view'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/hanami/view/issues'

  spec.required_ruby_version = ">= 3.2"

  spec.add_runtime_dependency "dry-configurable", "~> 1.0"
  spec.add_runtime_dependency "dry-core", "~> 1.0"
  spec.add_runtime_dependency "dry-inflector", "~> 1.0", "< 2"
  spec.add_runtime_dependency "temple", "~> 0.10.0", ">= 0.10.2"
  spec.add_runtime_dependency "tilt", "~> 2.3"
  spec.add_runtime_dependency "zeitwerk", "2.7.3"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
