# frozen_string_literal: true

require_relative "lib/monday/version"

version = Monday::VERSION
repository = "https://github.com/sanifhimani/monday_ruby"

Gem::Specification.new do |spec|
  spec.name = "monday_ruby"
  spec.version = version
  spec.authors = ["Sanif Himani", "Wes Hays"]
  spec.email = ["sanifhimani92@gmail.com", "weshays@gmail.com"]

  spec.summary = "Ruby bindings to use the monday.com API"
  spec.description = "A Gem to easily interact with monday.com API using native Ruby"
  spec.homepage = repository
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "documentation_uri" => "https://monday-ruby.gitbook.io/docs/",
    "changelog_uri" => "#{repository}/blob/v#{version}/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
