# Phase 17: Advanced Configuration Features

This phase implements advanced configuration features that exist in the original TypeScript herb but are not yet implemented in the Ruby version.

## Overview

The configuration schema (schema.json) already accepts these features for compatibility, but they are not yet implemented in the runtime.

| Feature | Description | Impact |
|---------|-------------|--------|
| failLevel | CI/CD exit code control | Build pipeline integration |
| files section | Top-level file patterns | Simplified configuration |
| Per-rule patterns | Rule-specific include/only/exclude | Fine-grained control |
| Per-rule enabled | Individual rule enable/disable | Flexibility |
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

- [ ] Read `linter.failLevel` from config
- [ ] Implement exit code logic based on failLevel
- [ ] Add `--fail-level` CLI option to override config
- [ ] Add unit tests
- [ ] Update integration tests

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

- [ ] Add `files_include_patterns` method
- [ ] Add `files_exclude_patterns` method
- [ ] Merge files patterns with linter patterns
- [ ] Add unit tests
- [ ] Update documentation

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
    - '**/*.html.erb'  # Added to files.include
  exclude:
    - 'tmp/**/*'       # Added to files.exclude
```

**Implementation:**

```ruby
# herb-config/lib/herb/config/linter_config.rb
class LinterConfig
  # @rbs config: Hash[String, untyped]
  def initialize(config)
    @config = config
  end

  # @rbs return: Array[String]
  def include_patterns
    files_include = @config.dig("files", "include") || []
    linter_include = @config.dig("linter", "include") || []
    files_include + linter_include
  end

  # @rbs return: Array[String]
  def exclude_patterns
    files_exclude = @config.dig("files", "exclude") || []
    linter_exclude = @config.dig("linter", "exclude") || []
    files_exclude + linter_exclude
  end
end
```

**Test Cases:**
- files.include merges with linter.include
- files.exclude merges with linter.exclude
- Empty files section uses only linter patterns
- Missing linter section uses only files patterns

---

## Part C: Per-Rule Configuration

### Task 17.3: Rule-Specific enabled Flag

**Location:** `herb-config/lib/herb/config/linter_config.rb`

- [ ] Add `rule_enabled?(rule_name)` method
- [ ] Update `rules` method to filter by enabled flag
- [ ] Add unit tests

**Location:** `herb-lint/lib/herb/lint/runner.rb`

- [ ] Filter rules by `enabled` flag
- [ ] Add integration tests

**Configuration:**

```yaml
# .herb.yml
linter:
  rules:
    html-alt-text: error
    html-attribute-quotes:
      enabled: false      # Disable this rule
      severity: warning
    html-deprecated-tags:
      enabled: true
      severity: error
```

**Implementation:**

```ruby
# herb-config/lib/herb/config/linter_config.rb
# @rbs rule_name: String
# @rbs return: bool
def rule_enabled?(rule_name)
  rule_config = @config.dig("linter", "rules", rule_name)
  return true if rule_config.nil?  # Not configured = enabled by default
  return true if rule_config.is_a?(String)  # String severity = enabled

  # Hash configuration
  rule_config.fetch("enabled", true)  # enabled defaults to true
end
```

**Test Cases:**
- Unconfigured rules are enabled by default
- String severity means enabled
- Hash with enabled: false disables rule
- Hash without enabled key defaults to true
- Disabled rules not run by Runner

---

### Task 17.4: Rule-Specific include/only/exclude Patterns

**Location:** `herb-config/lib/herb/config/linter_config.rb`

- [ ] Add `rule_include_patterns(rule_name)` method
- [ ] Add `rule_only_patterns(rule_name)` method
- [ ] Add `rule_exclude_patterns(rule_name)` method
- [ ] Add unit tests

**Location:** `herb-lint/lib/herb/lint/runner.rb`

- [ ] Apply per-rule pattern filtering
- [ ] Implement `only` pattern override logic
- [ ] Add integration tests

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

**Pattern Resolution Logic:**

```ruby
# For a given rule and file path:
# 1. If rule has 'only': file must match one of 'only' patterns
# 2. Else: file must match (linter.include OR rule.include)
# 3. AND: file must NOT match (linter.exclude OR rule.exclude)

def should_apply_rule?(rule_name, file_path)
  only = rule_only_patterns(rule_name)

  if only.any?
    # 'only' overrides all include patterns
    matches_only = only.any? { |pattern| File.fnmatch?(pattern, file_path) }
    return false unless matches_only
  else
    # Check include patterns
    all_includes = include_patterns + rule_include_patterns(rule_name)
    matches_include = all_includes.any? { |pattern| File.fnmatch?(pattern, file_path) }
    return false unless matches_include
  end

  # Check exclude patterns
  all_excludes = exclude_patterns + rule_exclude_patterns(rule_name)
  matches_exclude = all_excludes.any? { |pattern| File.fnmatch?(pattern, file_path) }
  return false if matches_exclude

  true
end
```

**Test Cases:**
- `only` overrides all include patterns
- `include` is additive to linter.include
- `exclude` is additive to linter.exclude
- Empty patterns use linter defaults
- Multiple patterns work correctly
- Glob matching works correctly

---

## Part D: Formatter Configuration (Deferred)

These tasks depend on `herb-format` gem implementation.

### Task 17.5: Formatter include/exclude Patterns

**Status:** ⏸️ Blocked by herb-format gem

**Location:** `herb-format/lib/herb/format/config.rb` (future)

- [ ] Read `formatter.include` from config
- [ ] Read `formatter.exclude` from config
- [ ] Merge with top-level `files` patterns
- [ ] Add unit tests

**Configuration:**

```yaml
# .herb.yml
files:
  exclude:
    - 'vendor/**/*'

formatter:
  include:
    - '**/*.html.erb'
  exclude:
    - 'tmp/**/*'
```

---

### Task 17.6: Formatter Rewriter Hooks

**Status:** ⏸️ Blocked by herb-format gem

**Location:** `herb-format/lib/herb/format/rewriter_pipeline.rb` (future)

- [ ] Implement RewriterRegistry
- [ ] Implement pre-format rewriter pipeline
- [ ] Implement post-format rewriter pipeline
- [ ] Add unit tests
- [ ] Document rewriter API

**Configuration:**

```yaml
# .herb.yml
formatter:
  rewriter:
    pre:
      - 'normalize-whitespace'
      - 'custom-preprocessor'
    post:
      - 'trim-trailing-spaces'
      - 'ensure-final-newline'
```

**Rewriter API:**

```ruby
module Herb
  module Format
    module Rewriter
      class Base
        # @rbs ast: Herb::AST::Node
        # @rbs return: Herb::AST::Node
        def rewrite(ast)
          # Transform AST
        end
      end
    end
  end
end
```

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

# Manual test - enabled flag
echo 'linter:
  rules:
    html-alt-text:
      enabled: false
      severity: error' > .herb.yml

herb-lint test.html.erb
# Should not report alt-text violations

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
| 17.1 | herb-lint | failLevel exit code control | Ready |
| 17.2 | herb-config | Top-level files section | Ready |
| 17.3 | herb-config + herb-lint | Per-rule enabled flag | Ready |
| 17.4 | herb-config + herb-lint | Per-rule include/only/exclude | Ready |
| 17.5 | herb-format | Formatter include/exclude | Blocked |
| 17.6 | herb-format | Rewriter hooks | Blocked |

**Total: 6 tasks (4 ready, 2 blocked)**

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
- Missing `enabled` defaults to `true`
- Missing per-rule patterns use global patterns

### Priority

**High Priority:**
- Task 17.1 (failLevel) - Important for CI/CD integration
- Task 17.3 (enabled flag) - Common use case

**Medium Priority:**
- Task 17.2 (files section) - Nice to have, not critical
- Task 17.4 (per-rule patterns) - Advanced feature, less common

**Deferred:**
- Tasks 17.5-17.6 - Blocked by herb-format implementation
