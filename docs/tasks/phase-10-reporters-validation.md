# Phase 10: Multiple Reporters & Configuration Validation

This phase implements medium-priority post-MVP features: additional output formats and configuration validation.

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| JsonReporter | JSON output format | CI/CD integration, tooling |
| GithubReporter | GitHub Actions annotations | PR workflow integration |
| Config Validator | Configuration file validation | Better error messages |
| Loader Search Path | Extended config file search | Flexibility |

## Prerequisites

- Phase 1-7 (MVP) complete
- Phase 9 (Inline Directives & Auto-fix) recommended but not required

---

## Part A: Multiple Reporters

### Task 10.1: JsonReporter Implementation

**Location:** `herb-lint/lib/herb/lint/reporter/json_reporter.rb`

- [x] Implement JsonReporter class
- [x] Add unit tests
- [x] Generate RBS types

**Interface:**

```ruby
module Herb
  module Lint
    module Reporter
      class JsonReporter < BaseReporter
        def report(result)
          # Output JSON to @output
        end
      end
    end
  end
end
```

**Output Format:**

```json
{
  "files": [
    {
      "path": "app/views/users/index.html.erb",
      "offenses": [
        {
          "rule": "alt-text",
          "severity": "error",
          "message": "Missing alt attribute on img tag",
          "line": 12,
          "column": 5,
          "endLine": 12,
          "endColumn": 35,
          "fixable": false
        }
      ]
    }
  ],
  "summary": {
    "fileCount": 2,
    "offenseCount": 3,
    "errorCount": 2,
    "warningCount": 1,
    "fixableCount": 1
  }
}
```

**Test Cases:**
- Empty result outputs valid JSON with empty files array
- Single file with offenses formatted correctly
- Multiple files aggregated correctly
- Summary counts accurate
- Fixable flag included

---

### Task 10.2: GithubReporter Implementation

**Location:** `herb-lint/lib/herb/lint/reporter/github_reporter.rb`

- [x] Implement GithubReporter class
- [x] Add unit tests
- [x] Generate RBS types

**Interface:**

```ruby
module Herb
  module Lint
    module Reporter
      class GithubReporter < BaseReporter
        def report(result)
          # Output GitHub Actions workflow commands
        end
      end
    end
  end
end
```

**Output Format:**

```
::error file=app/views/users/index.html.erb,line=12,col=5::Missing alt attribute on img tag (alt-text)
::warning file=app/views/users/index.html.erb,line=24,col=3::Prefer double quotes for attributes (attribute-quotes)
```

**Severity Mapping:**

| Lint Severity | GitHub Level |
|---------------|--------------|
| error | error |
| warning | warning |
| info | notice |
| hint | notice |

**Test Cases:**
- Error severity maps to ::error
- Warning severity maps to ::warning
- Info/hint severity maps to ::notice
- File path, line, column included
- Rule name appended to message

---

### Task 10.3: CLI --format and --github Options

**Location:** `herb-lint/lib/herb/lint/cli.rb`

- [x] Add `--format` option with detailed/simple/json choices
- [x] Add `--github` option (shortcut for GitHub reporter)
- [x] Update reporter factory logic
- [x] Add integration tests

**CLI Changes:**

```ruby
def parse_options
  # ... existing options ...
  opts.on("--format TYPE", %w[detailed simple json], "Output format") do |format|
    options[:format] = format
  end
  opts.on("--github", "Output GitHub Actions annotations") do
    options[:github] = true
  end
end

def create_reporter
  return Reporter::GithubReporter.new(output: @stdout) if @options[:github]

  case @options[:format]
  when "json"
    Reporter::JsonReporter.new(output: @stdout)
  when "simple"
    Reporter::SimpleReporter.new(output: @stdout)
  else
    Reporter::DetailedReporter.new(output: @stdout)
  end
end
```

---

## Part B: Configuration Validation

### Task 10.4: Validator Implementation

**Location:** `herb-config/lib/herb/config/validator.rb`

- [ ] Implement Validator class
- [ ] Add ValidationError to Errors module
- [ ] Add unit tests
- [ ] Generate RBS types

**Interface:**

```ruby
module Herb
  module Config
    class Validator
      def initialize(config, known_rules: [])
      def valid?  # => bool
      def validate!  # raises ValidationError if invalid
      def errors  # => Array[String]
    end
  end
end
```

**Validation Rules:**

| Field | Type | Validation |
|-------|------|------------|
| linter.enabled | boolean | Must be true/false |
| linter.include | array | Each element must be string |
| linter.exclude | array | Each element must be string |
| linter.rules | hash | Keys should be known rules |
| linter.rules.* | string/hash | Valid severity or hash with severity |
| formatter.enabled | boolean | Must be true/false |
| formatter.indentWidth | integer | Must be positive |
| formatter.maxLineLength | integer | Must be positive |

**Test Cases:**
- Valid configuration passes
- Invalid type for enabled field
- Invalid severity level
- Unknown rule name (warning, not error)
- Malformed glob pattern
- Missing required fields use defaults

---

### Task 10.5: Integrate Validator into Loader

**Location:** `herb-config/lib/herb/config/loader.rb`

- [ ] Call Validator after loading config
- [ ] Add `validate: true` option (default: true)
- [ ] Update integration tests

**Loader Changes:**

```ruby
def load(validate: true)
  config = load_from_file_or_defaults

  if validate
    validator = Validator.new(config, known_rules: @known_rules)
    validator.validate!
  end

  config
end
```

---

### Task 10.6: Loader Search Path Extension

**Location:** `herb-config/lib/herb/config/loader.rb`

- [ ] Add environment variable support (`HERB_CONFIG`, `HERB_NO_CONFIG`)
- [ ] Add upward directory traversal
- [ ] Add unit tests

**Search Order:**

1. Explicit `path:` parameter (error if not found)
2. `HERB_CONFIG` environment variable
3. Upward directory traversal from `working_dir`
4. Default configuration (if `HERB_NO_CONFIG` not set)

**Environment Variables:**

| Variable | Behavior |
|----------|----------|
| `HERB_CONFIG` | Use this path instead of searching |
| `HERB_NO_CONFIG` | Skip file search, use defaults only |

**Test Cases:**
- HERB_CONFIG overrides search
- HERB_NO_CONFIG returns defaults
- Upward traversal finds config in parent
- Stops at filesystem root

---

## Verification

### Part A: Multiple Reporters

```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/reporter/json_reporter_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/reporter/github_reporter_spec.rb

# Integration tests
cd herb-lint && ./bin/rspec spec/herb/lint/cli_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

**Manual Test:**

```bash
# JSON output
herb-lint --format json app/views/

# GitHub Actions output
herb-lint --github app/views/
```

### Part B: Configuration Validation

```bash
# Unit tests
cd herb-config && ./bin/rspec spec/herb/config/validator_spec.rb

# Integration tests
cd herb-config && ./bin/rspec spec/herb/config/loader_spec.rb

# Type check
cd herb-config && ./bin/steep check
```

**Manual Test:**

```yaml
# Invalid .herb.yml
linter:
  enabled: "yes"  # Should be boolean
  rules:
    unknown-rule: error  # Warning for unknown rule
```

```bash
herb-lint .
# Should show validation error message
```

---

## Summary

| Task | Component | Description |
|------|-----------|-------------|
| 10.1 | herb-lint | JsonReporter implementation |
| 10.2 | herb-lint | GithubReporter implementation |
| 10.3 | herb-lint | CLI --format and --github options |
| 10.4 | herb-config | Validator implementation |
| 10.5 | herb-config | Integrate Validator into Loader |
| 10.6 | herb-config | Loader search path extension |

**Total: 6 tasks**

## Related Documents

- [herb-lint Design](../design/herb-lint-design.md) - Reporter specs
- [herb-config Design](../design/herb-config-design.md) - Validator, Loader specs
- [herb-lint Requirements](../requirements/herb-lint.md) - Output format specs
