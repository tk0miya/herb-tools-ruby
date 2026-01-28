# Phase 9: Inline Directives & Auto-fix

This phase implements high-priority post-MVP features: inline directive support and auto-fix functionality.

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| Inline Directives | `<%# herb:disable rule-name %>` comments | Users can suppress specific violations |
| Auto-fix | `--fix` CLI option | Automatic code correction |

## Prerequisites

- Phase 1-7 (MVP) complete
- herb-core gem available

---

## Part A: Inline Directives

### Task 9.1: DirectiveParser Implementation

**Location:** `herb-core/lib/herb/core/directive_parser.rb`

- [ ] Implement DirectiveParser class
- [ ] Implement Directive data class
- [ ] Implement DirectiveType constants
- [ ] Add unit tests
- [ ] Generate RBS types

**Directive Types to Support:**

| Directive | Example | Scope |
|-----------|---------|-------|
| disable | `<%# herb:disable alt-text %>` | next line |
| disable all | `<%# herb:disable all %>` | next line |
| enable | `<%# herb:enable alt-text %>` | range end |
| enable all | `<%# herb:enable all %>` | range end |
| linter ignore | `<%# herb:linter ignore %>` | file |

**Interface:**

```ruby
module Herb
  module Core
    class DirectiveParser
      def initialize(source, mode: :linter)
      def parse  # => Array[Directive]
      def ignore_file?  # => bool
      def disabled_at?(line, rule_name = nil)  # => bool
    end

    class Directive
      attr_reader :type, :rules, :line, :scope
    end
  end
end
```

**Test Cases:**
- Parse single rule disable
- Parse multiple rules disable (comma-separated)
- Parse disable all
- Parse enable/enable all
- Parse file-level ignore
- Ignore non-directive comments
- Handle malformed directives gracefully

---

### Task 9.2: DisableTracker Implementation

**Location:** `herb-core/lib/herb/core/disable_tracker.rb`

- [ ] Implement DisableTracker class
- [ ] Add unit tests
- [ ] Generate RBS types

**Interface:**

```ruby
module Herb
  module Core
    class DisableTracker
      def initialize(directives)
      def ignore_file?  # => bool
      def rule_enabled_at?(line, rule_name)  # => bool
      def filter_enabled_rules(line, rule_names)  # => Array[String]
    end
  end
end
```

**Test Cases:**
- File-level ignore detection
- Single rule disable at specific line
- All rules disable at specific line
- Enable after disable (range)
- Multiple overlapping directives
- Rule enabled when no directives present

---

### Task 9.3: Integrate Directives into Linter

**Location:** `herb-lint/lib/herb/lint/linter.rb`

- [ ] Parse directives in `lint` method
- [ ] Check file-level ignore before processing
- [ ] Filter offenses by directive state
- [ ] Add integration tests
- [ ] Update RBS types

**Changes to Linter#lint:**

```ruby
def lint(file_path, source)
  # 1. Parse directives
  parser = Herb::Core::DirectiveParser.new(source, mode: :linter)
  tracker = Herb::Core::DisableTracker.new(parser.parse)

  # 2. Check file-level ignore
  return LintResult.new(file_path:, offenses: [], source:, ignored: true) if tracker.ignore_file?

  # 3. Run rules and collect offenses
  offenses = run_rules(source)

  # 4. Filter offenses by directives
  filtered = offenses.reject do |offense|
    !tracker.rule_enabled_at?(offense.line, offense.rule_name)
  end

  LintResult.new(file_path:, offenses: filtered, source:)
end
```

**Test Cases:**
- File with ignore directive returns ignored: true
- Disabled rule offenses are filtered out
- Enabled rules still report offenses
- Integration with actual rules

---

## Part B: Auto-fix Functionality

### Task 9.4: Fixer Class Implementation

**Location:** `herb-lint/lib/herb/lint/fixer.rb`

- [ ] Implement Fixer class
- [ ] Add unit tests
- [ ] Generate RBS types

**Interface:**

```ruby
module Herb
  module Lint
    class Fixer
      def initialize(source, offenses, fix_unsafely: false)
      def apply_fixes  # => String (modified source)
      def fixable_count  # => Integer
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

### Task 9.5: CLI --fix Option

**Location:** `herb-lint/lib/herb/lint/cli.rb`

- [ ] Add `--fix` option parsing
- [ ] Add `--fix-unsafely` option parsing
- [ ] Pass fix flags to Runner
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

---

### Task 9.6: Runner Fix Integration

**Location:** `herb-lint/lib/herb/lint/runner.rb`

- [ ] Accept fix options in constructor
- [ ] Apply fixes after linting each file
- [ ] Write fixed content back to file
- [ ] Add integration tests

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

### Task 9.7: Add fix Methods to Existing Rules

Update existing fixable rules to include fix Procs:

- [ ] `html/attribute-quotes` - Add fix method
- [ ] Add fix tests for each rule

**Example Fix Implementation:**

```ruby
# In Rules::Html::AttributeQuotes
def visit_html_attribute_node(node)
  return super(node) unless unquoted?(node.value)

  add_offense(
    message: "Attribute value should be quoted",
    location: node.value.location,
    node: node,
    fix: -> (source) {
      # Replace unquoted value with quoted value
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

### Part A: Inline Directives

```bash
# Unit tests
cd herb-core && ./bin/rspec spec/herb/core/directive_parser_spec.rb
cd herb-core && ./bin/rspec spec/herb/core/disable_tracker_spec.rb

# Integration test
cd herb-lint && ./bin/rspec spec/herb/lint/linter_spec.rb

# Type check
cd herb-core && ./bin/steep check
cd herb-lint && ./bin/steep check
```

**Manual Test:**

```erb
<%# test.html.erb %>
<%# herb:disable alt-text %>
<img src="decorative.png">

<img src="important.png">
```

```bash
herb-lint test.html.erb
# Should only report offense for second img tag
```

### Part B: Auto-fix

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
| 9.1 | herb-core | DirectiveParser implementation |
| 9.2 | herb-core | DisableTracker implementation |
| 9.3 | herb-lint | Integrate directives into Linter |
| 9.4 | herb-lint | Fixer class implementation |
| 9.5 | herb-lint | CLI --fix option |
| 9.6 | herb-lint | Runner fix integration |
| 9.7 | herb-lint | Add fix methods to existing rules |

**Total: 7 tasks**

## Related Documents

- [herb-core Design](../design/herb-core-design.md) - DirectiveParser, DisableTracker specs
- [herb-lint Design](../design/herb-lint-design.md) - Fixer spec
- [Future Enhancements](./future-enhancements.md) - Priority list
