# Phase 9: Inline Directives

This phase implements inline directive support and herb-disable-comment meta-rules.

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| Inline Directives | `<%# herb:disable rule-name %>` and `<%# herb:linter ignore %>` comments | Users can suppress specific violations |
| Meta-Rules | `herb-disable-comment-*` rules that validate directive comments | Catch typos and misuse in directives |

## Prerequisites

- Phase 1-7 (MVP) complete
- herb-lint gem available

---

## Part A: DirectiveParser

### Task 9.1: DirectiveParser Implementation

**Location:** `herb-lint/lib/herb/lint/directive_parser.rb`

- [x] Implement `DisableRuleName` Data class (name, offset, length)
- [x] Implement `DisableComment` Data class (match, rule_names, rule_name_details, rules_string)
- [x] Implement `Directives` Data class with `ignore_file?` and `disabled_at?` query methods
- [x] Implement `DirectiveParser.parse` class method (the only public method)
- [x] Add unit tests
- [x] Generate RBS types

**Design Notes:**

DirectiveParser is stateless. `parse` is the only public class method. It traverses the AST to detect `<%# herb:linter ignore %>` and scans lines for `<%# herb:disable ... %>` comments, returning a `Directives` object that holds all parsed results. Internal parsing helpers (e.g. parsing the content inside `<%# ... %>`) are private.

**Directive Types Supported:**

| Directive | Syntax | Scope | Purpose |
|-----------|--------|-------|---------|
| Line disable (specific) | `<%# herb:disable rule1, rule2 %>` | Same line | Suppress specific rules on that line |
| Line disable (all) | `<%# herb:disable all %>` | Same line | Suppress all rules on that line |
| File ignore | `<%# herb:linter ignore %>` | Entire file | Skip the entire file from linting |

**Data Structures:**

```ruby
module Herb
  module Lint
    class DirectiveParser
      HERB_DISABLE_PREFIX = "herb:disable"
      HERB_LINTER_IGNORE_PREFIX = "herb:linter ignore"

      # Parsed rule name with position information for error reporting.
      DisableRuleName = Data.define(
        :name,   #: String
        :offset, #: Integer
        :length  #: Integer
      )

      # Parsed herb:disable comment (including malformed ones).
      DisableComment = Data.define(
        :match,             #: bool -- whether the comment matched the herb:disable pattern
        :rule_names,        #: Array[String] -- list of rule name strings
        :rule_name_details, #: Array[DisableRuleName] -- rule names with position info
        :rules_string       #: String? -- raw rules portion of the comment
      )

      # Parse result holding all directive information for a file.
      # Meta-rules access `disable_comments` directly for validation.
      Directives = Data.define(
        :ignore_file,      #: bool
        :disable_comments  #: Hash[Integer, DisableComment]
      ) do
        def ignore_file? = ignore_file #: bool
        def disabled_at?(line, rule_name) #: bool
          # ...
        end
      end

      def self.parse(parse_result, source) #: Directives
        # ...
      end

      # All other parsing helpers are private class methods.
    end
  end
end
```

**Reference:** Corresponds to `herb-disable-comment-utils.ts` and `linter-ignore.ts` in the TypeScript implementation. Both operate on ERB comments and are unified here.

**Test Cases:**
- Parse single rule disable (`<%# herb:disable html-img-require-alt %>`)
- Parse multiple rules disable (comma-separated)
- Parse disable all (`<%# herb:disable all %>`)
- Parse file-level ignore (`<%# herb:linter ignore %>`)
- Ignore non-directive comments
- Malformed `herb:disable` comments are still stored in `disable_comments` (for meta-rule validation)
- `disabled_at?` returns true for matching rule on disabled line
- `disabled_at?` returns true for any rule when "all" is used
- `disabled_at?` returns false for non-disabled lines
- `disable_comments` contains `DisableComment` with correct `rule_name_details`

---

### Task 9.2: Integrate DirectiveParser into Linter

**Location:** `herb-lint/lib/herb/lint/linter.rb`, `herb-lint/lib/herb/lint/context.rb`, `herb-lint/lib/herb/lint/cli.rb`

- [x] Call `DirectiveParser.parse` in `Linter#lint` method
- [x] Implement `Linter#filter_offenses` private method
- [x] Update `Context` to carry `valid_rule_names` and `ignore_disable_comments`
- [x] Add `--ignore-disable-comments` CLI option
- [x] Add integration tests
- [x] Update RBS types

**Linter#lint Processing Flow:**

1. Parse ERB template into AST via `Herb.parse`
2. Parse directives via `DirectiveParser.parse(parse_result, source)` → `directives`
3. Check for file-level ignore via `directives.ignore_file?`; return empty result if found
4. Create Context with source, configuration, and rule_registry
5. Execute all rules against the AST and collect offenses
6. Build LintResult (filtering offenses and detecting unnecessary directives)

**Context:** No directive-related fields. Context provides `file_path`, `source`, `config`, and optional `rule_registry`.

**Test Cases:**
- File with `<%# herb:linter ignore %>` returns `ignored: true`
- Disabled rule offenses are filtered out on the same line
- Enabled rules still report offenses
- `--ignore-disable-comments` flag reports all offenses regardless of directives
- Integration with actual rules and directives

---

## Part B: herb-disable-comment Meta-Rules

All meta-rules are **non-excludable** (cannot be suppressed by `herb:disable` directives). Each accesses `context.directives.disable_comments` to iterate over the parsed `DisableComment` objects and validate their content.

### Task 9.3: herb-disable-comment-malformed

**Location:** `herb-lint/lib/herb/lint/rules/herb_disable_comment_malformed.rb`

- [x] Implement rule class
- [x] Register in `RuleRegistry`
- [x] Add unit tests
- [x] Generate RBS types

| Property | Value |
|----------|-------|
| Severity | error |
| Detects | Missing space after `herb:disable` prefix, trailing/leading/consecutive commas |

**Test Cases:**
- Non-directive comments produce no offense
- Valid `<%# herb:disable rule-name %>` produces no offense
- `<%# herb:disablerule-name %>` (missing space) produces offense
- `<%# herb:disable ,rule-name %>` (leading comma) produces offense
- `<%# herb:disable rule-name, %>` (trailing comma) produces offense
- `<%# herb:disable rule1,,rule2 %>` (consecutive commas) produces offense

---

### Task 9.4: herb-disable-comment-missing-rules

**Location:** `herb-lint/lib/herb/lint/rules/herb_disable_comment_missing_rules.rb`

- [x] Implement rule class
- [x] Register in `RuleRegistry`
- [x] Add unit tests
- [x] Generate RBS types

| Property | Value |
|----------|-------|
| Severity | error |
| Detects | `<%# herb:disable %>` with no rule names specified |

**Test Cases:**
- Non-directive comments produce no offense
- `<%# herb:disable rule-name %>` produces no offense
- `<%# herb:disable all %>` produces no offense
- `<%# herb:disable %>` (empty) produces offense

---

### Task 9.5: herb-disable-comment-no-duplicate-rules

**Location:** `herb-lint/lib/herb/lint/rules/herb_disable_comment_no_duplicate_rules.rb`

- [x] Implement rule class
- [x] Register in `RuleRegistry`
- [x] Add unit tests
- [x] Generate RBS types

| Property | Value |
|----------|-------|
| Severity | warning |
| Detects | Same rule listed more than once in one `herb:disable` comment |

**Test Cases:**
- Non-directive comments produce no offense
- `<%# herb:disable rule1, rule2 %>` (distinct rules) produces no offense
- `<%# herb:disable rule1, rule1 %>` (duplicate) produces offense with correct location on the second occurrence

---

### Task 9.6: herb-disable-comment-no-redundant-all

**Location:** `herb-lint/lib/herb/lint/rules/herb_disable_comment_no_redundant_all.rb`

- [x] Implement rule class
- [x] Register in `RuleRegistry`
- [x] Add unit tests
- [x] Generate RBS types

| Property | Value |
|----------|-------|
| Severity | warning |
| Detects | `all` used alongside specific rule names (the specific rules are redundant) |

**Test Cases:**
- Non-directive comments produce no offense
- `<%# herb:disable all %>` produces no offense
- `<%# herb:disable rule-name %>` produces no offense
- `<%# herb:disable all, rule-name %>` produces offense

---

### Task 9.7: herb-disable-comment-valid-rule-name

**Location:** `herb-lint/lib/herb/lint/rules/herb_disable_comment_valid_rule_name.rb`

- [x] Implement rule class
- [x] Register in `RuleRegistry`
- [x] Add unit tests
- [x] Generate RBS types

| Property | Value |
|----------|-------|
| Severity | warning |
| Detects | Unknown rule names in `herb:disable` comment |
| Context Dependency | `Context#valid_rule_names` |

Uses the list of registered rule names from `Context#valid_rule_names` to check whether each rule name in the directive is valid. Reports offense with "did you mean?" suggestions for close matches.

**Test Cases:**
- Non-directive comments produce no offense
- `<%# herb:disable html-img-require-alt %>` (valid rule) produces no offense
- `<%# herb:disable html-img-require-alts %>` (typo) produces offense with suggestion
- `<%# herb:disable nonexistent-rule %>` (unknown) produces offense

---

### Task 9.8: herb-disable-comment-unnecessary

**Location:** `herb-lint/lib/herb/lint/unnecessary_directive_detector.rb`

- [x] Implement `UnnecessaryDirectiveDetector` class
- [x] Integrate into Linter's `build_lint_result` method
- [x] Add unit tests (in `linter_spec.rb`)
- [x] Generate RBS types

| Property | Value |
|----------|-------|
| Rule name | `herb-disable-comment-unnecessary` |
| Severity | warning |
| Detects | `herb:disable` directive that does not suppress any actual offense |

**Design Note:** Not implemented as a rule. `UnnecessaryDirectiveDetector` is a stateless detector class called by the Linter after offense filtering. It computes directly from `directives` and `ignored_offenses`, without needing AST traversal. The `content_location` field on `DisableComment` (set by the `DirectiveParser::Collector` during parsing) provides the location information needed for offense reporting.

**Test Cases:**
- Non-directive comments produce no offense
- Directive that suppresses an offense produces no offense
- Directive on a line with no offenses produces offense
- Directive specifying a rule that has no offense on that line produces offense

---

## Verification

### Part A: DirectiveParser

```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/directive_parser_spec.rb

# Integration test
cd herb-lint && ./bin/rspec spec/herb/lint/linter_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

**Manual Test:**

```erb
<%# test.html.erb %>
<img src="decorative.png"> <%# herb:disable html-img-require-alt %>

<img src="important.png">
```

```bash
herb-lint test.html.erb
# Should only report offense for second img tag
```

### Part B: Meta-Rules

```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/rules/herb_disable_comment_malformed_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/rules/herb_disable_comment_missing_rules_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/rules/herb_disable_comment_no_duplicate_rules_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/rules/herb_disable_comment_no_redundant_all_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/rules/herb_disable_comment_valid_rule_name_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/rules/herb_disable_comment_unnecessary_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

---

## Summary

| Task | Component | Description |
|------|-----------|-------------|
| 9.1 | herb-lint | DirectiveParser implementation (data structures + parse methods) |
| 9.2 | herb-lint | Integrate DirectiveParser into Linter and Context |
| 9.3 | herb-lint | herb-disable-comment-malformed meta-rule |
| 9.4 | herb-lint | herb-disable-comment-missing-rules meta-rule |
| 9.5 | herb-lint | herb-disable-comment-no-duplicate-rules meta-rule |
| 9.6 | herb-lint | herb-disable-comment-no-redundant-all meta-rule |
| 9.7 | herb-lint | herb-disable-comment-valid-rule-name meta-rule |
| 9.8 | herb-lint | herb-disable-comment-unnecessary meta-rule |

**Total: 8 tasks** ✅

## Related Documents

- [herb-lint Design](../design/herb-lint-design.md) - DirectiveParser, Directives, meta-rules specs
- [Autofix Design](../design/herb-lint-autofix-design.md) - Autofix feature (moved to [Phase 15](./phase-15-autofix.md))
- [Future Enhancements](./future-enhancements.md) - Priority list
