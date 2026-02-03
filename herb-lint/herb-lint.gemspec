# frozen_string_literal: true

require_relative "lib/herb/lint/version"

Gem::Specification.new do |spec|
  spec.name = "herb-lint"
  spec.version = Herb::Lint::VERSION
  spec.authors = ["Claude"]
  spec.email = ["noreply@anthropic.com"]

  spec.summary = "Static analysis tool for ERB templates"
  spec.description = "A linter for ERB template files providing static analysis and code quality checks"
  spec.homepage = "https://github.com/tk0miya/herb-tools-ruby"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "herb"
  spec.add_dependency "herb-config", "~> 0.1.0"
  spec.add_dependency "herb-core", "~> 0.1.0"
  spec.add_dependency "herb-printer", "~> 0.1.0"
end
