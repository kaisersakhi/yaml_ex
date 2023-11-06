# frozen_string_literal: true

require_relative "lib/yaml_ex/version"

Gem::Specification.new do |spec|
  spec.name = "yaml_ex"
  spec.version = YamlEx::VERSION
  spec.authors = ["Kaiser Sakhi"]
  spec.email = ["mail@kaisersakhi.com"]

  spec.summary = "YAML templating engine."
  spec.description = "Extend YAML capabilities for templating, good for data scraping."
  spec.homepage = "https://github.com/kaisersakhi/yaml_ex"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kaisersakhi/yaml_ex"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "psych", "~> 3.3.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
