# frozen_string_literal: true

require_relative "lib/monday/version"

Gem::Specification.new do |spec|
  spec.name = "monday-ruby"
  spec.version = Monday::VERSION
  spec.authors = ["Sanif Himani"]
  spec.email = ["sanifhimani92@gmail.com"]

  spec.summary = "Ruby bindings to use the Monday.com API"
  spec.description = "A Gem to interact with the Monday.com API using native Ruby"
  spec.homepage = "https://github.com/sanifhimani/monday-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sanifhimani/monday-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/sanifhimani/monday-ruby"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
