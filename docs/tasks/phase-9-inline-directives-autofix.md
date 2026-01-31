# Phase 9: Inline Directives & Auto-fix

This phase implements high-priority post-MVP features: inline directive support, herb-disable-comment meta-rules, and auto-fix functionality.

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| Inline Directives | `<%# herb:disable rule-name %>` and `<%# herb:linter ignore %>` comments | Users can suppress specific violations |
| Meta-Rules | `herb-disable-comment-*` rules that validate directive comments | Catch typos and misuse in directives |
| Auto-fix | `--fix` CLI option | Automatic code correction |

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
- [x] Update `Context` to carry `directives`, `valid_rule_names`, `ignored_offenses_by_line`, and `ignore_disable_comments`
- [x] Add `--ignore-disable-comments` CLI option
- [x] Add integration tests
- [x] Update RBS types

**Linter#lint Processing Flow:**

1. Parse ERB template into AST via `Herb.parse`
2. Parse directives via `DirectiveParser.parse(parse_result, source)` → `directives`
3. Check for file-level ignore via `directives.ignore_file?`; return empty result if found
4. Create Context with source, configuration, `directives`, and directive-related fields
5. Execute each enabled rule against the AST (meta-rules access `context.directives.disable_comments` for validation)
6. For each rule's offenses, call `filter_offenses` using `directives`
7. Execute non-excludable meta-rules (herb-disable-comment-\* rules); these always run and cannot be suppressed by `herb:disable`
8. Execute `herb-disable-comment-unnecessary` last (requires `ignored_offenses_by_line` from step 6)
9. Return LintResult with kept offenses and ignored count

**filter_offenses:**

```ruby
# Filter offenses using the disable_comments from Directives.
# Returns a tuple of [kept_offenses, ignored_offenses].
# Also populates ignored_offenses_by_line to track which rule names
# were actually used to suppress offenses (needed by the "unnecessary" meta-rule).
def filter_offenses(offenses, rule_name, directives, ignored_offenses_by_line)
  # ...
end
```

**Context Changes:**

```ruby
class Context
  # Parsed directives for the current file.
  # Meta-rules access directives.disable_comments for validation.
  attr_reader :directives

  # List of valid rule names registered in the system.
  # Used by herb-disable-comment-valid-rule-name.
  attr_reader :valid_rule_names

  # Tracks which rule names were actually used to suppress offenses per line.
  # Populated by Linter#filter_offenses, consumed by herb-disable-comment-unnecessary.
  attr_reader :ignored_offenses_by_line

  # When true, report offenses even when suppressed by herb:disable comments.
  # Controlled by the --ignore-disable-comments CLI flag.
  attr_reader :ignore_disable_comments
end
```

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

- [ ] Implement rule class
- [ ] Register in `RuleRegistry`
- [ ] Add unit tests
- [ ] Generate RBS types

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

**Location:** `herb-lint/lib/herb/lint/rules/herb_disable_comment_unnecessary.rb`

- [ ] Implement rule class
- [ ] Register in `RuleRegistry`
- [ ] Add unit tests
- [ ] Generate RBS types

| Property | Value |
|----------|-------|
| Severity | warning |
| Detects | `herb:disable` directive that does not suppress any actual offense |
| Context Dependency | `Context#ignored_offenses_by_line` |

Uses `Context#ignored_offenses_by_line` (populated by `Linter#filter_offenses`) to determine whether a directive actually suppressed any offense on its line.

**Execution Order:** Must execute **after** all other rules and after offense filtering, because it needs to know which offenses were actually suppressed.

**Test Cases:**
- Non-directive comments produce no offense
- Directive that suppresses an offense produces no offense
- Directive on a line with no offenses produces offense
- Directive specifying a rule that has no offense on that line produces offense

---

## Part C: Auto-fix Functionality

### Task 9.9: Fixer Class Implementation

**Location:** `herb-lint/lib/herb/lint/fixer.rb`

- [x] Implement Fixer class
- [x] Add unit tests
- [x] Generate RBS types

**Interface:**

```ruby
module Herb
  module Lint
    class Fixer
      def initialize(source, offenses, fix_unsafely: false)
      def apply_fixes  # => String (modified source)
    end
  end
end
```

**Algorithm:**
1. Filter offenses to those with `fixable: true` and `fix` Proc
2. Sort by location (reverse order: end of file first)
3. Apply each fix Proc to source
4. Return modified source

**Test Cases:**
- No fixable offenses returns original source
- Single fix applied correctly
- Multiple fixes applied in correct order
- fix_unsafely flag respected
- Overlapping fixes handled

---

### Task 9.10: CLI --fix Option and Runner Integration

**Location:** `herb-lint/lib/herb/lint/cli.rb`, `herb-lint/lib/herb/lint/runner.rb`

- [ ] Add `--fix` option parsing in CLI
- [ ] Add `--fix-unsafely` option parsing in CLI
- [ ] Accept fix options in Runner constructor
- [ ] Apply fixes after linting each file in Runner
- [ ] Write fixed content back to file
- [ ] Add integration tests

**CLI Changes:**

```ruby
def parse_options
  # ... existing options ...
  opts.on("--fix", "Apply safe automatic fixes") do
    options[:fix] = true
  end
  opts.on("--fix-unsafely", "Apply all fixes including unsafe ones") do
    options[:fix] = true
    options[:fix_unsafely] = true
  end
end
```

**Runner Changes:**

```ruby
def lint_file(file_path)
  source = File.read(file_path)
  result = @linter.lint(file_path, source)

  if @fix && result.fixable_count > 0
    fixer = Fixer.new(source, result.offenses, fix_unsafely: @fix_unsafely)
    fixed_source = fixer.apply_fixes
    File.write(file_path, fixed_source) if fixed_source != source
  end

  result
end
```

---

### Task 9.11: Add fix Methods to Existing Rules

Update existing fixable rules to include fix Procs:

- [ ] `html-attribute-double-quotes` - Add fix method
- [ ] Add fix tests for each rule

**Example Fix Implementation:**

```ruby
# In Rules::HtmlAttributeDoubleQuotes
def visit_html_attribute_node(node)
  return super(node) unless wrong_quote_style?(node.value)

  add_offense(
    message: "Attribute value should use double quotes",
    location: node.value.location,
    node: node,
    fix: -> (source) {
      value = node.value.content
      replacement = %Q{"#{value}"}
      source[node.value.location.range] = replacement
      source
    }
  )

  super(node)
end
```

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

### Part C: Auto-fix

```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/fixer_spec.rb

# Integration test
cd herb-lint && ./bin/rspec spec/herb/lint/cli_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

**Manual Test:**

```erb
<%# test.html.erb %>
<div class=foo></div>
```

```bash
herb-lint --fix test.html.erb
cat test.html.erb
# Should show: <div class="foo"></div>
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
| 9.9 | herb-lint | Fixer class implementation |
| 9.10 | herb-lint | CLI --fix option and Runner integration |
| 9.11 | herb-lint | Add fix methods to existing rules |

**Total: 11 tasks**

## Related Documents

- [herb-lint Design](../design/herb-lint-design.md) - DirectiveParser, Directives, meta-rules, and Fixer specs
- [Future Enhancements](./future-enhancements.md) - Priority list
