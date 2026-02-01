# frozen_string_literal: true

require_relative "lib/herb/printer/version"

Gem::Specification.new do |spec|
  spec.name = "herb-printer"
  spec.version = Herb::Printer::VERSION
  spec.authors = ["Claude"]
  spec.email = ["noreply@anthropic.com"]

  spec.summary = "AST-to-source-code printer for ERB templates"
  spec.description = "Provides printer infrastructure for converting Herb AST back to source code, " \
                     "including lossless round-trip reconstruction"
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
end
