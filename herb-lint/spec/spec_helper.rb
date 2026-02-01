# frozen_string_literal: true

require "factory_bot"
require "herb/lint"

module TestHelpers
  def build_location(line:, column:)
    pos = Herb::Position.new(line, column)
    Herb::Location.new(pos, pos)
  end

  def build_offense(severity:, rule_name: "test-rule", message: "Test message", line: 1, column: 0)
    Herb::Lint::Offense.new(rule_name:, message:, severity:, location: build_location(line:, column:))
  end

  def build_lint_result(errors: 0, warnings: 0, file_path: "test.html.erb", source: "<div></div>")
    offenses = []
    errors.times { offenses << build_offense(severity: "error") }
    warnings.times { offenses << build_offense(severity: "warning") }

    Herb::Lint::LintResult.new(file_path:, offenses:, source:)
  end
end

FactoryBot.find_definitions

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include TestHelpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
