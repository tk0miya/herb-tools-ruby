# Phase 17: Advanced Configuration Features

This phase implements advanced configuration features that exist in the original TypeScript herb but are not yet implemented in the Ruby version.

## Overview

The configuration schema (schema.json) already accepts these features for compatibility, but they are not yet implemented in the runtime.

| Feature | Description | Impact |
|---------|-------------|--------|
| failLevel | CI/CD exit code control | Build pipeline integration |
| files section | Top-level file patterns | Simplified configuration |
| Per-rule patterns | Rule-specific include/only/exclude | Fine-grained control |
| Formatter patterns | Formatter-specific file patterns | Separation of concerns |
| Rewriter hooks | Pre/post-format transformations | Extensibility |

## Prerequisites

- Phase 10 (Validator) complete — schema.json already supports these features
- Phase 14 (herb-printer) complete for formatter features
- Phase 15 (Autofix) recommended

---

## Part A: Linter Exit Code Control

### Task 17.1: failLevel Implementation

**Location:** `herb-lint/lib/herb/lint/cli.rb`

- [x] Read `linter.failLevel` from config
- [x] Implement exit code logic based on failLevel
- [x] Add `--fail-level` CLI option to override config
- [x] Add unit tests
- [x] Update integration tests

**Configuration:**

```yaml
# .herb.yml
linter:
  failLevel: warning  # Exit with error on warnings and errors
  rules:
    html-alt-text: error
    html-attribute-quotes: warning  # This will cause exit code 1
    html-deprecated-tags: info      # This will NOT cause exit code 1
```

**Exit Code Logic:**

```ruby
# herb-lint/lib/herb/lint/cli.rb
def exit_code
  fail_level = @options[:fail_level] || @config.dig("linter", "failLevel") || "error"

  severity_rank = { "error" => 4, "warning" => 3, "info" => 2, "hint" => 1 }
  threshold = severity_rank[fail_level] || 4

  max_severity = @result.offenses
    .map { |offense| severity_rank[offense.severity] || 0 }
    .max || 0

  max_severity >= threshold ? 1 : 0
end
```

**CLI Option:**

```bash
herb-lint --fail-level warning app/views/
# Exit with error if warnings or errors found

herb-lint --fail-level error app/views/
# Exit with error only if errors found (default)
```

**Test Cases:**
- Default failLevel is "error"
- failLevel "warning" exits on warnings
- failLevel "info" exits on info and above
- CLI option overrides config
- No offenses returns exit code 0
- Offenses below threshold return exit code 0

---

## Part B: Top-level Files Configuration

### Task 17.2: files.include and files.exclude Support

**Location:** `herb-config/lib/herb/config/linter_config.rb`

- [x] Add `files_include_patterns` method
- [x] Add `files_exclude_patterns` method
- [x] Merge files patterns with linter patterns
- [x] Add unit tests
- [x] Update documentation

**Configuration:**

```yaml
# .herb.yml
files:
  include:
    - '**/*.xml.erb'
    - 'custom/**/*.html'
  exclude:
    - 'vendor/**/*'
    - 'node_modules/**/*'

linter:
  include:
    - '**/*.html.erb'  # Merged with files.include (additive)
  exclude:
    - 'tmp/**/*'       # Overrides files.exclude (precedence)
```

**Pattern Merge Behavior:**

- **`include` patterns**: ADDITIVE - Both `files.include` and `linter.include` are merged together
- **`exclude` patterns**: OVERRIDE - `linter.exclude` takes precedence; `files.exclude` is used only as fallback

**Implementation:**

```ruby
# herb-config/lib/herb/config/linter_config.rb
class LinterConfig
  # @rbs config: Hash[String, untyped]
  def initialize(config)
    @config = config
  end

  def include_patterns #: Array[String]
    # Additive: merge both arrays
    files_include = @config.dig("files", "include") || []
    linter_include = @config.dig("linter", "include") || []
    files_include + linter_include
  end

  def exclude_patterns #: Array[String]
    # Override: linter.exclude takes precedence
    @config.dig("linter", "exclude") || @config.dig("files", "exclude") || []
  end
end
```

**Test Cases:**
- files.include merges with linter.include (additive)
- files.exclude is overridden by linter.exclude when present
- linter.exclude takes precedence over files.exclude
- Empty files section uses only linter patterns
- Missing linter section uses only files patterns

---

## Part C: Per-Rule Configuration

### Task 17.4: Rule-Specific include/only/exclude Patterns

**Location:** `herb-config/lib/herb/config/linter_config.rb`

- [x] Use `build_pattern_matcher` to create matchers with rule-specific patterns

**Location:** `herb-lint/lib/herb/lint/linter.rb`

- [x] Use `rule.matcher.match?` for rule-specific pattern filtering
- [x] Add integration tests

**Configuration:**

```yaml
# .herb.yml
linter:
  include:
    - '**/*.html.erb'
  rules:
    html-alt-text:
      severity: error
      only:
        - 'app/views/**/*.html.erb'  # Only apply to app/views

    html-deprecated-tags:
      severity: warning
      include:
        - '**/*.xml.erb'  # Also check XML templates
      exclude:
        - 'legacy/**/*'   # Skip legacy code
```

**Implementation:**

```ruby
# Linter#collect_offenses
def collect_offenses(parse_result, context)
  rules.flat_map do |rule|
    next [] unless rule.matcher.match?(context.file_path)
    rule.check(parse_result, context)
  end
end
```

- Each rule gets a `PatternMatcher` via `RuleRegistry.build_all`
- `PatternMatcher` handles rule-specific `include`/`only`/`exclude` patterns
- Global `linter.include`/`exclude` applied during file discovery (Runner)

---

### Task 17.5: Rule Severity Configuration from Config File

**Location:** `herb-lint/lib/herb/lint/rules/rule_methods.rb`

This task implements the ability to override rule severity levels through configuration files, which was identified during Phase 17.1 implementation but deferred to keep the scope focused.

Currently, rule severity is determined solely by the rule's `default_severity` class method. This task adds the ability to override severity levels per-rule in the configuration file.

**Current Behavior:**
```ruby
# Rule severity is always the default
class ImgRequireAlt < VisitorRule
  def self.default_severity
    "error"  # Always "error", cannot be overridden
  end
end
```

**Desired Behavior:**
```yaml
# .herb.yml
linter:
  rules:
    html-img-require-alt:
      severity: warning  # Override from "error" to "warning"
```

#### Subtask 17.5.1: Rule Severity Resolution in RuleMethods

**Location:** `herb-lint/lib/herb/lint/rules/rule_methods.rb`

- [x] Modify `create_offense` to check config for severity override
- [x] Implement fallback chain: config > default_severity
- [x] Handle cases where @context is unavailable (unit tests)
- [x] Add unit tests for severity resolution

**Implementation:**
```ruby
def create_offense(message:, location:, autofix_context: nil)
  # Priority: config > instance severity (from default_severity)
  effective_severity = if @context.respond_to?(:config) && @context.config.respond_to?(:rule_severity)
                         @context.config.rule_severity(self.class.rule_name) || severity
                       else
                         severity
                       end
  Offense.new(rule_name: self.class.rule_name, message:, severity: effective_severity,
              location:, autofix_context:)
end
```

#### Subtask 17.5.2: Update Context Factory for Tests

**Location:** `herb-lint/spec/factories/context.rb`

- [x] Change `rule_registry` from `nil` to `Herb::Lint::RuleRegistry.new`
- [x] Ensures `Context#severity_for` can resolve rule default severities
- [x] Update tests that rely on the factory

**Current:**
```ruby
rule_registry { nil }
```

**Updated:**
```ruby
rule_registry { Herb::Lint::RuleRegistry.new }
```

#### Subtask 17.5.3: Add Integration Tests

**Location:** `herb-lint/spec/herb/lint/cli_spec.rb`

- [x] Test: Severity override from config is respected
- [x] Test: failLevel with overridden severity works correctly
- [x] Test: Multiple rules with different severity overrides

**Test Example:**
```ruby
context "when offenses are below threshold due to severity override" do
  let(:argv) { ["--fail-level", "error"] }

  before do
    File.write(".herb.yml", <<~YAML)
      linter:
        rules:
          html-img-require-alt:
            severity: warning  # Override from error to warning
          erb-prefer-image-tag-helper:
            enabled: false
    YAML
    create_file("app/views/test.html.erb", '<img src="test.png">')
  end

  it "returns EXIT_SUCCESS when only warnings exist and failLevel is error" do
    expect(subject).to eq(described_class::EXIT_SUCCESS)
  end
end
```

**Benefits:**
1. **Flexibility**: Projects can adjust rule severity without modifying code
2. **Gradual Adoption**: Start with warnings, move to errors over time
3. **Context-Specific**: Different severity levels for different environments
4. **Compatibility**: Matches behavior of TypeScript herb implementation

**Verification:**
```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/rules/rule_methods_spec.rb

# Integration tests
cd herb-lint && ./bin/rspec spec/herb/lint/cli_spec.rb

# Manual test
echo 'linter:
  rules:
    html-img-require-alt:
      severity: warning' > .herb.yml

echo '<img src="test.png">' > test.html.erb
herb-lint test.html.erb
# Should show "warning" not "error"
```

---

## Part D: Formatter Configuration (Moved to Phase 22)

Formatter-related configuration tasks have been moved to [Phase 22: Future Enhancements](./phase-22-future-enhancements.md) as they depend on `herb-format` gem implementation:

- **Task 17.6** → Future Enhancement #11: Formatter include/exclude Patterns
- **Task 17.7** → Future Enhancement #12: Formatter Rewriter Hooks

These features will be implemented after the herb-format gem is complete.

---

## Verification

### Part A: failLevel

```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/cli_spec.rb

# Manual test
echo 'linter:
  failLevel: warning
  rules:
    html-alt-text: warning' > .herb.yml

herb-lint test.html.erb
echo $?  # Should be 1 if warnings found
```

### Part B: files section

```bash
# Unit tests
cd herb-config && ./bin/rspec spec/herb/config/linter_config_spec.rb

# Manual test
echo 'files:
  include: ["**/*.xml.erb"]
  exclude: ["vendor/**/*"]' > .herb.yml

herb-lint --verbose .
# Should show files.include and files.exclude being used
```

### Part C: Per-rule configuration

```bash
# Unit tests
cd herb-config && ./bin/rspec spec/herb/config/linter_config_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/runner_spec.rb

# Manual test - only patterns
echo 'linter:
  rules:
    html-alt-text:
      severity: error
      only: ["app/views/**/*"]' > .herb.yml

herb-lint lib/views/test.html.erb
# Should not check lib/views (not in app/views)
```

---

## Summary

| Task | Component | Description | Status |
|------|-----------|-------------|--------|
| 17.1 | herb-lint | failLevel exit code control | ✅ Completed |
| 17.2 | herb-config | Top-level files section | ✅ Completed |
| 17.4 | herb-config + herb-lint | Per-rule include/only/exclude | ✅ Completed |
| 17.5 | herb-lint | Rule severity config override | ✅ Completed |
| 17.6 | herb-format | Formatter include/exclude | Blocked |
| 17.7 | herb-format | Rewriter hooks | Blocked |

**Total: 6 tasks (4 completed, 0 ready, 2 blocked)**

**Note:** Task 17.5 addresses rule severity configuration from config files, which was identified during Phase 17.1 implementation and initially deferred. Tasks 17.6-17.7 have been moved to [Phase 22: Future Enhancements](./phase-22-future-enhancements.md) as they depend on herb-format gem implementation.

## Related Documents

- [herb-config Design](../design/herb-config-design.md) - Configuration schema
- [herb-lint Design](../design/herb-lint-design.md) - Runner and CLI specs
- [Phase 10: Reporters & Validation](./phase-10-reporters-validation.md) - Validator implementation
- [Phase 14: herb-printer](./phase-14-herb-printer.md) - Required for formatter
- [Future Enhancements](./future-enhancements.md) - Other post-MVP features

## Implementation Notes

### Schema Compatibility

The JSON schema in `herb-config/lib/herb/config/schema.json` already validates these features. The Validator will accept configurations using these features without errors.

### Backward Compatibility

All new features are optional and backward compatible:
- Missing `failLevel` defaults to "error" (current behavior)
- Missing `files` section uses `linter`/`formatter` sections only
- Missing per-rule patterns use global patterns

### Priority

**High Priority:**
- Task 17.1 (failLevel) - Important for CI/CD integration

**Medium Priority:**
- Task 17.2 (files section) - Nice to have, not critical
- Task 17.4 (per-rule patterns) - Advanced feature, less common
- Task 17.5 (rule severity override) - Flexibility for gradual adoption

**Moved to Phase 22:**
- Tasks 17.6-17.7 - Formatter features moved to Future Enhancements
