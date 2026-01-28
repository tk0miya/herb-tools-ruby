# Phase 6: Reporter & CLI Implementation

## Overview

Implementation of Reporter to display results and command-line interface. This enables end users to use the `herb-lint` command.

**Dependencies:** Phase 5 (Linter & Runner) must be completed

**Task count:** 2

---

## Task 6.1: Implement SimpleReporter

### Implementation

- [x] Create `lib/herb/lint/reporter/simple_reporter.rb`
  - [x] Implement `initialize(io: $stdout)`
  - [x] `attr_reader :io`
  - [x] Implement `report(aggregated_result)` method
    - [x] Display offenses for each file
    - [x] Offense information (file name, line number, column number, rule name, message, severity)
    - [x] Display summary (file count, offense count, error count, warning count)
  - [x] Private methods
    - [x] `print_offenses(result)` - Display offenses for individual file
    - [x] `print_summary(aggregated_result)` - Display summary
- [x] Require in `lib/herb/lint.rb`
- [x] Create `spec/herb/lint/reporter/simple_reporter_spec.rb`
  - [x] Test offense display
  - [x] Test summary display
  - [x] Test case with no offenses

### Output Format Example

```
app/views/users/show.html.erb
  5:10  error    img tag should have an alt attribute  html/alt-text
  12:3  warning  Attribute value should be quoted       html/attribute-quotes

app/views/posts/index.html.erb
  8:15  error    img tag should have an alt attribute  html/alt-text

3 problems (2 errors, 1 warning) in 2 files
```

### Implementation Hints

```ruby
def report(aggregated_result)
  aggregated_result.results.each do |result|
    print_offenses(result) if result.offense_count > 0
  end

  print_summary(aggregated_result)
end

private

def print_offenses(result)
  io.puts result.file_path
  result.offenses.each do |offense|
    io.puts format(
      "  %d:%d  %-8s  %-40s  %s",
      offense.line,
      offense.column,
      offense.severity,
      offense.message,
      offense.rule_name
    )
  end
  io.puts
end

def print_summary(aggregated_result)
  total = aggregated_result.offense_count
  errors = aggregated_result.error_count
  warnings = aggregated_result.warning_count
  files = aggregated_result.file_count

  io.puts "#{total} problems (#{errors} errors, #{warnings} warnings) in #{files} files"
end
```

### Verification

```bash
bundle exec rspec spec/herb/lint/reporter/simple_reporter_spec.rb
```

**Expected result:** All tests pass

---

## Task 6.2: Implement CLI

### Implementation

- [ ] Create `lib/herb/lint/cli.rb`
  - [ ] Implement `initialize(argv)`
  - [ ] Define exit code constants
    - [ ] `EXIT_SUCCESS = 0` (no offenses)
    - [ ] `EXIT_LINT_ERROR = 1` (offenses found)
    - [ ] `EXIT_RUNTIME_ERROR = 2` (runtime error)
  - [ ] Implement `run` method
    - [ ] Parse arguments (`--version`, `--help`, path specification)
    - [ ] `--version`: Display version and exit (exit code 0)
    - [ ] `--help`: Display help and exit (exit code 0)
    - [ ] Path specification: Execute lint
    - [ ] No arguments: Execute lint in current directory
  - [ ] Load Config (`Herb::Config::Loader.load`)
  - [ ] Call `RuleRegistry.load_builtin_rules`
  - [ ] Execute Runner
  - [ ] Display Reporter
  - [ ] Determine exit code
    - [ ] No offenses: exit code 0
    - [ ] Offenses found: exit code 1
    - [ ] Runtime error: exit code 2 (configuration error, file I/O error, etc.)
  - [ ] Implement error handling
    - [ ] Catch configuration file errors, file I/O errors, etc.
- [ ] Require in `lib/herb/lint.rb`
- [ ] Create `spec/herb/lint/cli_spec.rb`
  - [ ] Test `--version`
  - [ ] Test `--help`
  - [ ] Test path specification
  - [ ] Test no arguments
  - [ ] Test exit codes

### Implementation Hints

```ruby
module Herb
  module Lint
    class CLI
      EXIT_SUCCESS = 0       # No offenses
      EXIT_LINT_ERROR = 1    # Offenses found
      EXIT_RUNTIME_ERROR = 2 # Runtime error

      def initialize(argv)
        @argv = argv
      end

      def run
        if @argv.include?("--version")
          puts "herb-lint #{Herb::Lint::VERSION}"
          return EXIT_SUCCESS
        end

        if @argv.include?("--help")
          print_help
          return EXIT_SUCCESS
        end

        # Register builtin rules to RuleRegistry
        RuleRegistry.load_builtin_rules

        # Load configuration
        config_hash = Herb::Config::Loader.load
        config = Herb::Config::LinterConfig.new(config_hash)

        # Get paths (empty array if no arguments)
        paths = @argv.reject { |arg| arg.start_with?("-") }

        # Execute Runner
        runner = Runner.new(config)
        result = runner.run(paths)

        # Display Reporter
        reporter = Reporter::SimpleReporter.new
        reporter.report(result)

        # Determine exit code
        result.success? ? EXIT_SUCCESS : EXIT_LINT_ERROR
      rescue => e
        # Runtime error (configuration error, file I/O error, etc.)
        $stderr.puts "Error: #{e.message}"
        $stderr.puts e.backtrace if ENV["DEBUG"]
        EXIT_RUNTIME_ERROR
      end

      private

      def print_help
        puts <<~HELP
          Usage: herb-lint [options] [paths...]

          Options:
            --version    Show version
            --help       Show this help

          Examples:
            herb-lint                          # Lint all files in current directory
            herb-lint app/views                # Lint files in app/views
            herb-lint app/views/users/*.erb    # Lint specific files

          Exit codes:
            0  No offenses found
            1  Offenses found
            2  Runtime error (configuration error, file I/O error, etc.)
        HELP
      end
    end
  end
end
```

### exe/herb-lint Contents

```ruby
#!/usr/bin/env ruby

require "herb/lint"

exit_code = Herb::Lint::CLI.new(ARGV).run
exit exit_code
```

### Verification

```bash
bundle exec rspec spec/herb/lint/cli_spec.rb

# Manual testing
bundle exec exe/herb-lint --version
bundle exec exe/herb-lint --help
```

**Expected result:** All tests pass, CLI commands work

---

## Phase 6 Completion Criteria

- [ ] All tasks (6.1–6.2) completed
- [ ] `bundle exec rspec` passes all tests
- [ ] `bundle exec exe/herb-lint --version` works
- [ ] `bundle exec exe/herb-lint --help` works
- [ ] Can execute lint on actual ERB files

---

## Next Phase

After Phase 6 is complete, proceed to [Phase 7: Integration Tests & Documentation](./phase-7-integration.md).
