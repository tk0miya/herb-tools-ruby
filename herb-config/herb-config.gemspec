# frozen_string_literal: true

require_relative "lib/herb/config/version"

Gem::Specification.new do |spec|
  spec.name = "herb-config"
  spec.version = Herb::Config::VERSION
  spec.authors = ["Claude"]
  spec.email = ["noreply@anthropic.com"]

  spec.summary = "Configuration management for herb-tools-ruby"
  spec.description = "Loads .herb.yml configuration files and provides settings for herb-lint and herb-format"
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

  # TODO: Uncomment when herb gem is available
  # spec.add_dependency "herb", "~> 0.1"
end
