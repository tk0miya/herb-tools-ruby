# Phase 23: JSON Reporter Summary Fields Completion

This phase completes the JSON reporter implementation by adding support for additional severity levels and rule counting.

## Overview

| Feature | Description | Status |
|---------|-------------|--------|
| Severity tracking | Add info/hint severity support | 📋 |
| Ignored offenses count | Track suppressed offenses | 📋 |
| Rule count | Report active rule count | 📋 |

## Background

The TypeScript reference implementation includes these fields in the JSON summary:
- `totalInfo`: Count of info-level offenses
- `totalHints`: Count of hint-level offenses
- `totalIgnored`: Count of suppressed offenses (via herb:disable)
- `ruleCount`: Number of active rules

Currently, these are hardcoded to `0` in the Ruby implementation.

## Prerequisites

- Phase 10 complete (JsonReporter implemented)
- TypeScript format alignment complete (commit c30a6df)

---

## Task 23.1: Add Info and Hint Severity Levels

**Goal:** Extend the severity system to support `info` and `hint` levels.

### Implementation

**Location:** `herb-lint/lib/herb/lint/aggregated_result.rb`

- [x] Add `info_count` method
- [x] Add `hint_count` method
- [x] Update tests in `spec/herb/lint/aggregated_result_spec.rb`

**Location:** `herb-lint/lib/herb/lint/lint_result.rb`

- [x] Add `info_count` method
- [x] Add `hint_count` method
- [x] Update tests in `spec/herb/lint/lint_result_spec.rb`

**Location:** `herb-lint/lib/herb/lint/reporter/json_reporter.rb`

- [x] Update `build_summary` to use actual `info_count` and `hint_count`
- [x] Update tests in `spec/herb/lint/reporter/json_reporter_spec.rb`

**Verification:**
```bash
cd herb-lint
./bin/rspec spec/herb/lint/aggregated_result_spec.rb
./bin/rspec spec/herb/lint/lint_result_spec.rb
./bin/rspec spec/herb/lint/reporter/json_reporter_spec.rb
```

### Example Implementation

```ruby
# herb-lint/lib/herb/lint/aggregated_result.rb
module Herb
  module Lint
    class AggregatedResult
      # ... existing methods ...

      def info_count #: Integer
        results.sum(&:info_count)
      end

      def hint_count #: Integer
        results.sum(&:hint_count)
      end
    end
  end
end
```

```ruby
# herb-lint/lib/herb/lint/lint_result.rb
module Herb
  module Lint
    class LintResult
      # ... existing methods ...

      def info_count #: Integer
        offenses.count { |offense| offense.severity == "info" }
      end

      def hint_count #: Integer
        offenses.count { |offense| offense.severity == "hint" }
      end
    end
  end
end
```

```ruby
# herb-lint/lib/herb/lint/reporter/json_reporter.rb
def build_summary(aggregated_result) #: Hash[String, Integer]
  files_with_offenses = aggregated_result.results.count { |result| result.offenses.any? }

  {
    "filesChecked" => aggregated_result.file_count,
    "filesWithOffenses" => files_with_offenses,
    "totalErrors" => aggregated_result.error_count,
    "totalWarnings" => aggregated_result.warning_count,
    "totalInfo" => aggregated_result.info_count,        # NEW
    "totalHints" => aggregated_result.hint_count,       # NEW
    "totalIgnored" => 0,  # TODO: Task 23.2
    "totalOffenses" => aggregated_result.offense_count,
    "ruleCount" => 0      # TODO: Task 23.3
  }
end
```

---

## Task 23.2: Track Ignored Offenses Count

**Goal:** Count offenses that were suppressed by `herb:disable` directives.

### Analysis

Currently, `DirectiveParser` filters offenses but doesn't track the count of ignored offenses. We need to:
1. Extend `LintResult` to include ignored offenses
2. Update `Linter#lint` to track ignored offenses
3. Aggregate ignored counts in `AggregatedResult`

### Implementation

**Location:** `herb-lint/lib/herb/lint/lint_result.rb`

- [x] Add `ignored_offenses` attribute (default: `[]`)
- [x] Add `ignored_count` method
- [x] Update initializer to accept `ignored_offenses` parameter
- [x] Update tests

**Location:** `herb-lint/lib/herb/lint/linter.rb`

- [x] Update `lint` method to track ignored offenses from `Directives#filter_offenses`
- [x] Pass ignored offenses to `LintResult.new`
- [x] Update tests to verify ignored offenses are tracked

**Location:** `herb-lint/lib/herb/lint/aggregated_result.rb`

- [x] Add `ignored_count` method
- [x] Update tests

**Location:** `herb-lint/lib/herb/lint/reporter/json_reporter.rb`

- [x] Update `build_summary` to use actual `ignored_count`
- [x] Update tests

**Verification:**
```bash
cd herb-lint
./bin/rspec spec/herb/lint/lint_result_spec.rb
./bin/rspec spec/herb/lint/linter_spec.rb
./bin/rspec spec/herb/lint/aggregated_result_spec.rb
./bin/rspec spec/herb/lint/reporter/json_reporter_spec.rb
```

### Example Implementation

```ruby
# herb-lint/lib/herb/lint/lint_result.rb
module Herb
  module Lint
    class LintResult
      attr_reader :file_path, :offenses, :parse_result, :ignored_offenses

      # @rbs file_path: String
      # @rbs offenses: Array[Offense]
      # @rbs parse_result: Herb::ParseResult?
      # @rbs ignored_offenses: Array[Offense]
      def initialize(file_path:, offenses:, parse_result: nil, ignored_offenses: [])
        @file_path = file_path
        @offenses = offenses
        @parse_result = parse_result
        @ignored_offenses = ignored_offenses
      end

      def ignored_count #: Integer
        ignored_offenses.size
      end
    end
  end
end
```

```ruby
# herb-lint/lib/herb/lint/linter.rb
def lint(file_path, source)
  # ... existing code ...

  # Filter offenses based on directives
  filtered, ignored = directives.filter_offenses(offenses_before_filter)

  # ... existing code ...

  LintResult.new(
    file_path:,
    offenses: filtered,
    parse_result:,
    ignored_offenses: ignored  # NEW
  )
end
```

---

## Task 23.3: Report Active Rule Count

**Goal:** Include the count of active (non-disabled) rules in the JSON summary.

### Analysis

The rule count should reflect the number of rules actually used during linting, accounting for:
- Rules enabled in configuration
- Rules disabled via configuration
- Built-in rules vs. custom rules

### Implementation

**Location:** `herb-lint/lib/herb/lint/runner.rb`

- [x] Track active rule count in runner
- [x] Pass rule count to `AggregatedResult`

**Location:** `herb-lint/lib/herb/lint/aggregated_result.rb`

- [x] Add `rule_count` attribute
- [x] Update initializer to accept `rule_count` parameter
- [x] Update tests

**Location:** `herb-lint/lib/herb/lint/reporter/json_reporter.rb`

- [x] Update `build_summary` to use actual `rule_count`
- [x] Update tests

**Verification:**
```bash
cd herb-lint
./bin/rspec spec/herb/lint/runner_spec.rb
./bin/rspec spec/herb/lint/aggregated_result_spec.rb
./bin/rspec spec/herb/lint/reporter/json_reporter_spec.rb
```

### Example Implementation

```ruby
# herb-lint/lib/herb/lint/aggregated_result.rb
module Herb
  module Lint
    class AggregatedResult
      attr_reader :results, :rule_count

      # @rbs results: Array[LintResult]
      # @rbs rule_count: Integer
      def initialize(results, rule_count: 0)
        @results = results
        @rule_count = rule_count
      end
    end
  end
end
```

```ruby
# herb-lint/lib/herb/lint/runner.rb
def run(paths)
  # ... existing code ...

  rule_count = linter.rules.size

  AggregatedResult.new(results, rule_count:)
end
```

---

## Task 23.4: Update RBS Type Signatures

**Goal:** Ensure type signatures are updated for all changes.

### Implementation

- [x] Run `rbs-inline` to generate RBS types
- [x] Verify type signatures with `steep check`
- [x] Update manual RBS files if needed

**Verification:**
```bash
cd herb-lint
./bin/rake steep
```

---

## Task 23.5: Integration Testing

**Goal:** Verify the complete JSON output with all fields populated correctly.

### Implementation

**Location:** `herb-lint/spec/herb/lint/reporter/json_reporter_spec.rb`

- [x] Add test case with info-level offenses
- [x] Add test case with hint-level offenses
- [x] Add test case with ignored offenses
- [x] Verify rule count is accurate
- [x] Add integration test with mixed severities

### Example Test

```ruby
context "when results include all severity levels" do
  let(:results) do
    [
      build(:lint_result,
            file_path: "app/views/test.html.erb",
            offenses: [
              build(:offense, severity: "error"),
              build(:offense, severity: "warning"),
              build(:offense, severity: "info"),
              build(:offense, severity: "hint")
            ],
            ignored_offenses: [
              build(:offense, severity: "warning")
            ])
    ]
  end

  it "reports all severity counts correctly" do
    subject

    summary = parsed_output["summary"]
    expect(summary["totalErrors"]).to eq(1)
    expect(summary["totalWarnings"]).to eq(1)
    expect(summary["totalInfo"]).to eq(1)
    expect(summary["totalHints"]).to eq(1)
    expect(summary["totalIgnored"]).to eq(1)
    expect(summary["totalOffenses"]).to eq(4)
  end
end
```

**Verification:**
```bash
cd herb-lint
./bin/rspec spec/herb/lint/reporter/json_reporter_spec.rb
./bin/rake
```

---

## Task 23.6: Update Documentation

**Goal:** Update documentation to reflect the complete JSON format.

### Implementation

**Location:** `docs/requirements/herb-lint.md`

- [ ] Verify JSON output format is up-to-date
- [ ] Add examples showing all severity levels
- [ ] Document the meaning of each summary field

**Verification:** Manual review of documentation

---

## Success Criteria

All tasks completed and verified:
- [x] Task 23.1: Info/hint severity levels implemented
- [x] Task 23.2: Ignored offenses count tracked
- [x] Task 23.3: Active rule count reported
- [x] Task 23.4: RBS types updated
- [x] Task 23.5: Integration tests passing
- [ ] Task 23.6: Documentation updated

**Full verification:**
```bash
cd herb-lint
./bin/rake  # All checks pass (RSpec, RuboCop, Steep)
```

---

## Related Issues

This phase completes the JSON reporter alignment with the TypeScript reference implementation initiated in commit c30a6df.

## Future Enhancements

- Consider adding `totalFixable` count (requires autofix metadata)
- Consider adding timing information (currently `null`)
- Consider adding custom messages for different scenarios
