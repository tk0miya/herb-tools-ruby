# Phase 1: Formatter Foundation

This phase establishes the foundational infrastructure for herb-format, including gem setup, core data structures, and configuration support.

**Design document:** [herb-format-design.md](../design/herb-format-design.md)

**Reference:** TypeScript `@herb-tools/formatter` package

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| Gem scaffold | Create herb-format gem with proper structure | Establishes project foundation |
| Data structures | FormatResult, AggregatedResult, Context | Core formatting workflow support |
| Configuration | Extend herb-config with FormatterConfig | Enables .herb.yml formatter section |
| Error handling | Custom exception classes | Clear error reporting |

## Prerequisites

- herb-config gem complete
- herb-core gem complete
- herb-printer gem complete (Phase 14)
- herb gem available (AST parsing)

## Design Principles

1. **Separate gem** - Matches TypeScript package structure `@herb-tools/formatter`
2. **Reuse infrastructure** - Leverage herb-config, herb-core, herb-printer
3. **Type safety** - Use RBS inline annotations from the start
4. **Test-driven** - Write tests alongside implementation

---

## Part A: Gem Scaffold

### Task 1.1: Create Gem Directory Structure

**Location:** `herb-format/`

- [x] Create directory structure matching herb-lint pattern
  ```
  herb-format/
  ├── bin/                 # Binstubs
  ├── lib/
  │   └── herb/
  │       └── format/
  │           └── version.rb
  ├── exe/
  │   └── herb-format      # Executable
  ├── spec/
  │   └── herb/
  │       └── format/
  ├── sig/generated/       # Auto-generated RBS
  ├── .gitignore
  ├── .rspec
  ├── .rubocop.yml
  ├── Gemfile
  ├── Rakefile
  ├── Steepfile
  ├── herb-format.gemspec
  ├── rbs_collection.yaml
  └── rbs_collection.lock.yaml
  ```
- [x] Copy and adapt configuration files from herb-lint
- [x] Update .gitignore for formatter-specific patterns

**Verification:**
- Directory structure exists
- No files missing from template

---

### Task 1.2: Create Gemspec

**Location:** `herb-format/herb-format.gemspec`

- [ ] Create gemspec file based on herb-lint template
- [ ] Set name to "herb-format"
- [ ] Set version to "0.1.0"
- [ ] Add runtime dependencies:
  - herb (~> 0.1)
  - herb-config (~> 0.1)
  - herb-core (~> 0.1)
  - herb-printer (~> 0.1)
- [ ] Add development dependencies:
  - rake
  - rspec (~> 3.13)
  - rubocop (~> 1.69)
  - rbs-inline (~> 0.8)
  - steep (~> 1.9)
  - factory_bot (~> 6.5)
- [ ] Set required_ruby_version to >= 3.3.0

**Verification:**
- `gem build herb-format.gemspec` succeeds
- All dependencies resolve

---

### Task 1.3: Create Binstubs

**Location:** `herb-format/bin/`

- [ ] Create binstubs following herb-lint pattern:
  - bin/rake
  - bin/rspec
  - bin/rubocop
  - bin/rbs
  - bin/rbs-inline
  - bin/steep
- [ ] Make all binstubs executable (chmod +x)
- [ ] Each binstub uses herb-format/Gemfile

**Verification:**
- `cd herb-format && ./bin/rake --version` works
- `cd herb-format && ./bin/rspec --version` works

---

### Task 1.4: Create Gemfile and Bundle

**Location:** `herb-format/Gemfile`

- [ ] Create Gemfile sourcing rubygems.org
- [ ] Add `gemspec` directive
- [ ] Add path dependencies for local gems:
  ```ruby
  gem "herb-config", path: "../herb-config"
  gem "herb-core", path: "../herb-core"
  gem "herb-printer", path: "../herb-printer"
  ```
- [ ] Run `bundle install`
- [ ] Commit Gemfile.lock

**Verification:**
- `bundle install` succeeds
- No dependency conflicts

---

### Task 1.5: Create Rakefile

**Location:** `herb-format/Rakefile`

- [ ] Create Rakefile with default task running all checks
- [ ] Add RSpec task
- [ ] Add RuboCop task
- [ ] Add Steep task
- [ ] Default task runs: rspec, rubocop, steep

**Verification:**
- `cd herb-format && ./bin/rake` runs all tasks
- Individual tasks work: `./bin/rake spec`, `./bin/rake rubocop`, `./bin/rake steep`

---

### Task 1.6: Add CI Configuration

**Location:** `.github/workflows/ci.yml` (root level)

- [ ] Add herb-format job to `.github/workflows/ci.yml`
- [ ] Configure job to run in herb-format directory
- [ ] Set up Ruby 3.3 and bundler cache
- [ ] Run `bundle exec rake` for all checks

**CI Configuration to Add:**

Add the following job to `.github/workflows/ci.yml` after the `herb-lint` job:

```yaml
herb-format:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: herb-format
  steps:
    - uses: actions/checkout@v6
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.3'
        bundler-cache: true
        working-directory: herb-format
    - name: Run all checks
      run: bundle exec rake
```

**Verification:**
- `.github/workflows/ci.yml` includes herb-format job
- Job configuration matches other gems (herb-config, herb-core, herb-lint)
- CI will run when this branch is pushed (verification happens after Task 1.7-1.9 complete)

---

### Task 1.7: Create RSpec Configuration

**Location:** `herb-format/.rspec`, `herb-format/spec/spec_helper.rb`

- [ ] Create .rspec with format and color settings
- [ ] Create spec_helper.rb based on herb-lint template
- [ ] Configure RSpec to require spec_helper
- [ ] Add FactoryBot configuration
- [ ] Create spec/support/factory_bot.rb

**Verification:**
- `cd herb-format && ./bin/rspec` runs (no specs yet)
- Output shows "0 examples, 0 failures"

---

### Task 1.9: Create RBS and Steep Configuration

**Location:** `herb-format/Steepfile`, `herb-format/rbs_collection.yaml`

- [ ] Create Steepfile based on herb-lint template
- [ ] Configure target "lib" pointing to lib/
- [ ] Configure signature and library paths
- [ ] Create rbs_collection.yaml
- [ ] Run `rbs collection install`

**Verification:**
- `cd herb-format && ./bin/steep check` runs (no files yet)
- `rbs collection install` succeeds

---

### Task 1.9: Create Version File

**Location:** `herb-format/lib/herb/format/version.rb`

- [ ] Create version.rb defining VERSION constant
- [ ] Set VERSION = "0.1.0"
- [ ] Add module structure:
  ```ruby
  # rbs_inline: enabled

  module Herb
    module Format
      VERSION = "0.1.0"
    end
  end
  ```

**Verification:**
- File can be required without error
- `Herb::Format::VERSION` returns "0.1.0"

---

### Task 1.10: Create Entry Point

**Location:** `herb-format/lib/herb/format.rb`

- [ ] Create lib/herb/format.rb as gem entry point
- [ ] Require version file
- [ ] Require herb dependencies (herb, herb-config, herb-core, herb-printer)
- [ ] Define Herb::Format module structure

**Template:**
```ruby
# rbs_inline: enabled

require_relative "format/version"

require "herb"
require "herb/config"
require "herb/core"
require "herb/printer"

module Herb
  module Format
    # Component requires will be added as we implement them
  end
end
```

**Verification:**
- `ruby -Ilib -rherbformat -e 'puts Herb::Format::VERSION'` works

---

## Part B: Data Structures

### Task 1.11: Create FormatResult

**Location:** `herb-format/lib/herb/format/format_result.rb`

- [ ] Create FormatResult as Data.define class
- [ ] Add fields: file_path, original, formatted, ignored, error
- [ ] Implement predicate methods: ignored?, error?, changed?
- [ ] Implement diff method returning unified diff string
- [ ] Implement to_h for serialization
- [ ] Add RBS inline type annotations
- [ ] Create spec file with comprehensive tests

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Represents the formatting result for a single file.
    #
    # @rbs file_path: String
    # @rbs original: String
    # @rbs formatted: String
    # @rbs ignored: bool
    # @rbs error: StandardError?
    class FormatResult < Data
      # @rbs file_path: String
      # @rbs original: String
      # @rbs formatted: String
      # @rbs ignored: bool
      # @rbs error: StandardError?
      # @rbs return: void
      def initialize(file_path:, original:, formatted:, ignored: false, error: nil)
        super(file_path:, original:, formatted:, ignored:, error:)
      end

      # @rbs return: bool
      def ignored? = ignored

      # @rbs return: bool
      def error? = !error.nil?

      # @rbs return: bool
      def changed? = original != formatted

      # @rbs return: String?
      def diff
        return nil unless changed?
        # Generate unified diff
      end

      # @rbs return: Hash[Symbol, untyped]
      def to_h
        {
          file_path:,
          changed: changed?,
          ignored: ignored?,
          error: error&.message
        }
      end
    end
  end
end
```

**Test Cases:**
- FormatResult with no changes: changed? returns false
- FormatResult with changes: changed? returns true, diff returns string
- FormatResult ignored: ignored? returns true
- FormatResult with error: error? returns true
- to_h serialization includes all fields

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/format_result_spec.rb`
- All tests pass

---

### Task 1.12: Create AggregatedResult

**Location:** `herb-format/lib/herb/format/aggregated_result.rb`

- [ ] Create AggregatedResult as Data.define class
- [ ] Add field: results (Array[FormatResult])
- [ ] Implement aggregation methods: file_count, changed_count, ignored_count, error_count
- [ ] Implement all_formatted? predicate
- [ ] Implement to_h for serialization
- [ ] Add RBS inline type annotations
- [ ] Create spec file with comprehensive tests

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Aggregates formatting results across multiple files.
    #
    # @rbs results: Array[FormatResult]
    class AggregatedResult < Data
      # @rbs results: Array[FormatResult]
      # @rbs return: void
      def initialize(results:)
        super(results:)
      end

      # @rbs return: Integer
      def file_count = results.size

      # @rbs return: Integer
      def changed_count = results.count(&:changed?)

      # @rbs return: Integer
      def ignored_count = results.count(&:ignored?)

      # @rbs return: Integer
      def error_count = results.count(&:error?)

      # @rbs return: bool
      def all_formatted? = changed_count.zero? && error_count.zero?

      # @rbs return: Hash[Symbol, untyped]
      def to_h
        {
          file_count:,
          changed_count:,
          ignored_count:,
          error_count:,
          all_formatted: all_formatted?
        }
      end
    end
  end
end
```

**Test Cases:**
- AggregatedResult with empty results: counts are all zero
- AggregatedResult with mixed results: counts correct
- all_formatted? returns true when no changes or errors
- to_h serialization includes all aggregated data

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/aggregated_result_spec.rb`
- All tests pass

---

### Task 1.13: Create Context

**Location:** `herb-format/lib/herb/format/context.rb`

- [ ] Create Context as Data.define class
- [ ] Add fields: file_path, source, config
- [ ] Add cached source_lines field
- [ ] Implement convenience methods: indent_width, max_line_length
- [ ] Implement source_line(line) and line_count methods
- [ ] Add RBS inline type annotations
- [ ] Create spec file with comprehensive tests

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Provides contextual information during formatting and rewriting.
    #
    # @rbs file_path: String
    # @rbs source: String
    # @rbs config: Herb::Config::FormatterConfig
    # @rbs source_lines: Array[String]?
    class Context < Data
      # @rbs file_path: String
      # @rbs source: String
      # @rbs config: Herb::Config::FormatterConfig
      # @rbs return: void
      def initialize(file_path:, source:, config:)
        super(file_path:, source:, config:, source_lines: nil)
      end

      # @rbs return: Integer
      def indent_width = config.indent_width

      # @rbs return: Integer
      def max_line_length = config.max_line_length

      # @rbs line: Integer
      # @rbs return: String
      def source_line(line)
        split_source_lines[line - 1] || ""
      end

      # @rbs return: Integer
      def line_count = split_source_lines.size

      private

      # @rbs return: Array[String]
      def split_source_lines
        @source_lines ||= source.lines(chomp: false)
      end
    end
  end
end
```

**Test Cases:**
- Context delegates indent_width to config
- Context delegates max_line_length to config
- source_line returns correct line (1-indexed)
- line_count returns correct count
- source_lines cached after first access

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/context_spec.rb`
- All tests pass

---

## Part C: Configuration and Error Handling

### Task 1.14: Extend FormatterConfig in herb-config

**Location:** `herb-config/lib/herb/config/formatter_config.rb`

- [ ] Add indent_width field (Integer, default: 2)
- [ ] Add max_line_length field (Integer, default: 80)
- [ ] Add rewriter_pre field (Array[String], default: [])
- [ ] Add rewriter_post field (Array[String], default: [])
- [ ] Update validation to check indent_width > 0
- [ ] Update validation to check max_line_length > 0
- [ ] Update RBS type annotations
- [ ] Create/update spec file

**Interface:**
```ruby
# In herb-config gem
class FormatterConfig < Data
  # ... existing fields (enabled, include, exclude) ...

  # @rbs indent_width: Integer
  # @rbs max_line_length: Integer
  # @rbs rewriter_pre: Array[String]
  # @rbs rewriter_post: Array[String]

  def initialize(
    enabled: true,
    include: DEFAULT_INCLUDE,
    exclude: DEFAULT_EXCLUDE,
    indent_width: 2,
    max_line_length: 80,
    rewriter_pre: [],
    rewriter_post: []
  )
    super(
      enabled:,
      include:,
      exclude:,
      indent_width:,
      max_line_length:,
      rewriter_pre:,
      rewriter_post:
    )
  end

  def validate!
    # ... existing validations ...
    raise ConfigurationError, "indentWidth must be positive" unless indent_width.positive?
    raise ConfigurationError, "maxLineLength must be positive" unless max_line_length.positive?
  end
end
```

**Test Cases:**
- FormatterConfig with defaults has correct indent_width and max_line_length
- FormatterConfig with custom values accepts them
- validate! raises on negative indent_width
- validate! raises on negative max_line_length
- rewriter_pre and rewriter_post default to empty arrays

**Verification:**
- `cd herb-config && ./bin/rspec spec/herb/config/formatter_config_spec.rb`
- All tests pass

---

### Task 1.15: Update Config Loader for Formatter Fields

**Location:** `herb-config/lib/herb/config/loader.rb`

- [ ] Update YAML loading to parse formatter.indentWidth
- [ ] Update YAML loading to parse formatter.maxLineLength
- [ ] Update YAML loading to parse formatter.rewriter.pre (array)
- [ ] Update YAML loading to parse formatter.rewriter.post (array)
- [ ] Handle camelCase → snake_case conversion
- [ ] Update spec file with new fields

**Test Cases:**
- Load .herb.yml with formatter.indentWidth: 4
- Load .herb.yml with formatter.maxLineLength: 120
- Load .herb.yml with formatter.rewriter.pre: ["normalize-attributes"]
- Load .herb.yml with formatter.rewriter.post: ["tailwind-class-sorter"]
- Defaults apply when fields omitted

**Verification:**
- `cd herb-config && ./bin/rspec spec/herb/config/loader_spec.rb`
- All tests pass

---

### Task 1.16: Create Error Classes

**Location:** `herb-format/lib/herb/format/errors.rb`

- [ ] Create Errors module with custom exception classes
- [ ] Define base Error class
- [ ] Define ConfigurationError
- [ ] Define ParseError
- [ ] Define RewriterError
- [ ] Define FileNotFoundError
- [ ] Add RBS inline type annotations

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    module Errors
      class Error < StandardError; end

      class ConfigurationError < Error; end
      class ParseError < Error; end
      class RewriterError < Error; end
      class FileNotFoundError < Error; end
    end
  end
end
```

**Verification:**
- Error classes defined and inherit correctly
- Can be raised and rescued

---

### Task 1.17: Wire Up Part B and C Components

**Location:** `herb-format/lib/herb/format.rb`

- [ ] Add require_relative for format_result
- [ ] Add require_relative for aggregated_result
- [ ] Add require_relative for context
- [ ] Add require_relative for errors
- [ ] Run rbs-inline to generate signatures
- [ ] Run steep check

**Verification:**
- `ruby -Ilib -rherbformat -e 'puts Herb::Format::FormatResult'` works
- `cd herb-format && ./bin/steep check` passes
- No require errors

---

## Part D: Integration Testing

### Task 1.18: Create FactoryBot Factories

**Location:** `herb-format/spec/factories/`

- [ ] Create factories/format_results.rb
- [ ] Create factory for FormatResult with sensible defaults
- [ ] Create factory for AggregatedResult
- [ ] Create factory for Context (requires FormatterConfig)

**Example:**
```ruby
FactoryBot.define do
  factory :format_result, class: "Herb::Format::FormatResult" do
    file_path { "test.html.erb" }
    original { "<div>test</div>" }
    formatted { "<div>test</div>" }
    ignored { false }
    error { nil }

    trait :changed do
      formatted { "<div>\n  test\n</div>" }
    end

    trait :ignored do
      ignored { true }
    end

    trait :with_error do
      error { StandardError.new("Parse error") }
    end
  end
end
```

**Verification:**
- `build(:format_result)` works in specs
- Traits work correctly

---

### Task 1.19: Full Verification

- [ ] Run `cd herb-format && ./bin/rake` -- all checks pass
- [ ] Run `cd herb-config && ./bin/rake` -- all checks pass (after formatter config changes)
- [ ] Verify gem can be built: `gem build herb-format.gemspec`
- [ ] Verify all data structures work together
- [ ] Verify type checking passes
- [ ] Verify CI runs successfully on GitHub Actions (after pushing to branch)

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| 1.1-1.10 | A | Gem scaffold, boilerplate, and CI setup |
| 1.11 | B | FormatResult data structure |
| 1.12 | B | AggregatedResult data structure |
| 1.13 | B | Context data structure |
| 1.14-1.15 | C | FormatterConfig extension |
| 1.16 | C | Error classes |
| 1.17 | C | Wire up components |
| 1.18-1.19 | D | Integration testing |

**Total: 19 tasks**

## Related Documents

- [herb-format Design](../design/herb-format-design.md)
- [herb-format Requirements](../requirements/herb-format.md)
- [Configuration Specification](../requirements/config.md)
- [Architecture](../design/architecture.md)
