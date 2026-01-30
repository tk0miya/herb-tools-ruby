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

> **Design Decision:** Inline directive parsing is implemented in herb-lint (not herb-core), following the TypeScript reference implementation where `herb-disable-comment-utils.ts` and `linter-ignore.ts` reside in the linter package. The `enable` directive is not supported (it does not exist in the TS version). Responsibilities are clearly separated: container (DisableComment), collection/parsing (DisableCommentParser), data management + judgment (DisableDirectives).

### Task 9.1: DisableComment Data Class

**Location:** `herb-lint/lib/herb/lint/disable_comment.rb`

- [x] Implement DisableComment data class using Data.define
- [x] Add unit tests
- [x] Generate RBS types

**Interface:**

```ruby
module Herb
  module Lint
    DisableComment = Data.define(:rule_names, :line) do
      def disables_all?  # => bool
      def disables_rule?(rule_name)  # => bool
    end
  end
end
```

**Test Cases:**
- Value equality
- disables_all? with "all" in rule_names
- disables_rule? with specific and all rules

---

### Task 9.2: DisableCommentParser Module

**Location:** `herb-lint/lib/herb/lint/disable_comment_parser.rb`

- [x] Implement DisableCommentParser module
- [x] Add unit tests
- [x] Generate RBS types

**Directive Types to Support:**

| Directive | Example | Scope |
|-----------|---------|-------|
| disable | `<%# herb:disable alt-text %>` | next line |
| disable all | `<%# herb:disable all %>` | next line |
| disable multiple | `<%# herb:disable alt-text, html/lowercase-tags %>` | next line |

> **Note:** The `enable` directive is intentionally omitted. It does not exist in the TypeScript reference implementation.

**Interface:**

```ruby
module Herb
  module Lint
    module DisableCommentParser
      def self.parse(source)  # => DisableDirectives
      def self.parse_line(line, line_number:)  # => DisableComment?
    end
  end
end
```

**Test Cases:**
- parse returns DisableDirectives with collected comments
- parse detects linter ignore directive
- parse handles both disable and ignore together
- parse_line parses single/multiple/all rules
- parse_line ignores non-directive comments
- Handle whitespace variations

---

### Task 9.2b: DisableDirectives Class

**Location:** `herb-lint/lib/herb/lint/disable_directives.rb`

- [x] Implement DisableDirectives class (data management + judgment)
- [x] Add unit tests
- [x] Generate RBS types

**Interface:**

```ruby
module Herb
  module Lint
    class DisableDirectives
      def initialize(comments:, ignore_file:)
      def ignore_file?  # => bool
      def rule_disabled?(line, rule_name)  # => bool
    end
  end
end
```

**Test Cases:**
- ignore_file? returns correct value
- rule_disabled? checks target line (next line after comment)
- rule_disabled? handles "all" rules
- rule_disabled? returns false for non-target lines
- Multiple disable comments handled correctly

---

### Task 9.3: Integrate Directives into Linter

**Location:** `herb-lint/lib/herb/lint/linter.rb`

- [x] Check file-level ignore before processing
- [x] Build disable cache from source
- [x] Filter offenses by disable cache
- [x] Add integration tests
- [x] Update RBS types

**Changes to Linter#lint:**

```ruby
def lint(file_path:, source:)
  directives = DisableCommentParser.parse(source)
  return ignored_result(file_path, source) if directives.ignore_file?

  document = Herb.parse(source)
  offenses = collect_offenses(document, build_context(file_path, source))
  filtered = offenses.reject { |o| directives.rule_disabled?(o.line, o.rule_name) }
  LintResult.new(file_path:, offenses: filtered, source:)
end
```

**Test Cases:**
- File with ignore directive returns ignored: true
- Disabled rule offenses are filtered out
- Non-matching disable rules still report offenses
- Disable only applies to next line
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
cd herb-lint && ./bin/rspec spec/herb/lint/disable_comment_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/disable_comment_parser_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/disable_directives_spec.rb

# Integration test
cd herb-lint && ./bin/rspec spec/herb/lint/linter_spec.rb

# Type check
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
| 9.1 | herb-lint | DisableComment data class |
| 9.2 | herb-lint | DisableCommentParser module |
| 9.2b | herb-lint | DisableDirectives class (data + judgment) |
| 9.3 | herb-lint | Integrate directives into Linter |
| 9.4 | herb-lint | Fixer class implementation |
| 9.5 | herb-lint | CLI --fix option |
| 9.6 | herb-lint | Runner fix integration |
| 9.7 | herb-lint | Add fix methods to existing rules |

**Total: 8 tasks**

## Related Documents

- [herb-lint Design](../design/herb-lint-design.md) - DisableComment, DisableCommentParser, DisableDirectives, Fixer specs
- [herb-core Design](../design/herb-core-design.md) - Shared infrastructure (file discovery)
- [Future Enhancements](./future-enhancements.md) - Priority list
