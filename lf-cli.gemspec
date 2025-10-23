require_relative 'lib/langfuse/cli/version'

Gem::Specification.new do |spec|
  spec.name          = "lf-cli"
  spec.version       = Langfuse::CLI::VERSION
  spec.authors       = ["Vicente Reig Rincon de Arellano"]
  spec.email         = ["hey@vicente.services"]

  spec.summary       = "An open-source CLI for Langfuse®"
  spec.description   = "Unofficial command-line interface for querying and analyzing Langfuse LLM observability data. This is a community project not affiliated with Langfuse GmbH."
  spec.homepage      = "https://github.com/vicentereig/lf-cli"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{lib,bin}/**/*") + %w[README.md LICENSE CHANGELOG.md]
  spec.bindir = "bin"
  spec.executables = ["lf"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "thor", "~> 1.3"              # CLI framework
  spec.add_dependency "faraday", "~> 2.0"           # HTTP client
  spec.add_dependency "faraday-retry", "~> 2.0"     # Retry middleware
  spec.add_dependency "terminal-table", "~> 3.0"    # ASCII tables
  spec.add_dependency "tty-prompt", "~> 0.23"       # Interactive prompts
  spec.add_dependency "tty-table", "~> 0.12"        # Enhanced tables
  spec.add_dependency "tty-spinner", "~> 0.9"       # Loading spinners
  spec.add_dependency "pastel", "~> 0.8"            # Terminal colors
  spec.add_dependency "chronic", "~> 0.10"          # Natural language dates
  spec.add_dependency "csv", "~> 3.0"               # CSV support (Ruby 3.4+)
  spec.add_dependency "sorbet-runtime", "~> 0.5"    # Runtime type checking

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "vcr", "~> 6.2"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "byebug", "~> 11.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
end
