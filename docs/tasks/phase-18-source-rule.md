# Source Rule Introduction

This task introduces the `SourceRule` base class for rules that operate on raw source strings rather than the AST. This aligns with the TypeScript reference implementation's `SourceRule` pattern.

**Design document:** [herb-lint-autofix-design.md](../design/herb-lint-autofix-design.md) (Source Rule Design section)

**Reference:** TypeScript `@herb-tools/linter` `SourceRule` class and `erb-no-extra-newline` / `erb-require-trailing-newline` rules

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| Unified AutofixContext | Extend with `start_offset` / `end_offset` for source rules | Enables offset-based autofix |
| SourceRule base class | New base class for source-level rules | Clean abstraction for source rules |
| Autofixer source phase | Two-phase autofix: AST phase + source phase | Enables source rule autofix |
| NoExtraNewline migration | Migrate from `Base` to `SourceRule`, add autofix | First source rule with autofix |

## Prerequisites

- Phase 15 Part A complete (AutofixContext, RuleMethods, NodeLocator)
- Phase 15 Part B: Task 15.5 complete (Autofixer implementation)
- herb-printer gem available (IdentityPrinter)

## Design Principles

1. **Unified AutofixContext** -- A single `AutofixContext` class with optional `node` (Visitor Rule) and optional `start_offset`/`end_offset` (Source Rule). Rule type is determined by field presence, not by separate classes.
2. **Offset verification, not recalculation** -- During autofix, the rule verifies that the content at the recorded offsets still matches the expected pattern. If the content has shifted (due to a prior fix), the fix is skipped. Offsets are never recalculated.
3. **Two-phase autofix** -- AST fixes are applied first and serialized to source. Source fixes then operate on the resulting string.
4. **Interface compatibility** -- `SourceRule#check` accepts `(parse_result, context)` like `VisitorRule`, so `Linter#collect_offenses` needs no type dispatch.

---

## Part A: Infrastructure

### Task S.1: Extend AutofixContext with Source Rule Support

**Location:** `herb-lint/lib/herb/lint/autofix_context.rb`

- [x] Add `start_offset` and `end_offset` optional fields to `AutofixContext`
- [x] Add `source_rule?` method -- returns `true` when `start_offset` is present
- [x] Add `visitor_rule?` method -- returns `true` when `node` is present
- [x] Ensure all fields are optional with defaults (`node: nil`, `start_offset: nil`, `end_offset: nil`)
- [x] Verify backward compatibility: existing `AutofixContext.new(node:, rule:)` still works
- [x] Update unit tests
- [x] Update RBS types

**Data Structure:**

```ruby
AutofixContext = Data.define(:rule_class, :node, :start_offset, :end_offset) do
  def initialize(rule_class:, node: nil, start_offset: nil, end_offset: nil)
    super
  end

  def source_rule?
    !start_offset.nil?
  end

  def visitor_rule?
    !node.nil?
  end

  def autofixable?(unsafe: false)
    return true if rule_class.safe_autofixable?
    return true if unsafe && rule_class.unsafe_autofixable?
    false
  end
end
```

**Test Cases:**
- `AutofixContext.new(rule_class: R, node: n)` -- `visitor_rule?` is `true`, `source_rule?` is `false`
- `AutofixContext.new(rule_class: R, start_offset: 10, end_offset: 20)` -- `source_rule?` is `true`, `visitor_rule?` is `false`
- `autofixable?` delegates correctly for both variants
- Backward compatibility: existing creation patterns work without changes

---

### Task S.2: Create SourceRule Base Class

**Location:** `herb-lint/lib/herb/lint/rules/source_rule.rb`

- [ ] Create `SourceRule` class inheriting from `Base`
- [ ] Implement `check(_parse_result, context)` -- delegates to `check_source`
- [ ] Define abstract `check_source(source, context)` -- raises `NotImplementedError`
- [ ] Define default `autofix_source(offense, source)` -- returns `nil`
- [ ] Implement `add_offense_with_source_autofix(message:, location:, start_offset:, end_offset:)` -- creates `AutofixContext` with offsets
- [ ] Extract `location_from_offsets` helper from `NoExtraNewline` into `SourceRule`
- [ ] Extract `position_from_offset` helper from `NoExtraNewline` into `SourceRule`
- [ ] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [ ] Add unit tests

**Interface:**

```ruby
class SourceRule < Base
  def check(_parse_result, context)
    @offenses = []
    @context = context
    @source = context.source
    check_source(@source, context)
    @offenses
  end

  def check_source(_source, _context)
    raise NotImplementedError, "#{self.class.name} must implement #check_source"
  end

  def autofix_source(_offense, _source)
    nil
  end

  def add_offense_with_source_autofix(message:, location:, start_offset:, end_offset:)
    context = AutofixContext.new(rule_class: self.class, start_offset:, end_offset:)
    add_offense(message:, location:, autofix_context: context)
  end

  private

  def location_from_offsets(start_offset, end_offset)
    # ... (extracted from NoExtraNewline)
  end

  def position_from_offset(offset)
    # ... (extracted from NoExtraNewline)
  end
end
```

**Test Cases:**
- `check` delegates to `check_source` with `context.source`
- `check` ignores the `parse_result` argument
- `check_source` raises `NotImplementedError` by default
- `autofix_source` returns `nil` by default
- `add_offense_with_source_autofix` creates offense with `AutofixContext` containing offsets
- `location_from_offsets` correctly converts byte offsets to `Herb::Location`
- `position_from_offset` handles newlines correctly (0-indexed line/column)

---

### Task S.3: Extend Autofixer with Source Phase

**Location:** `herb-lint/lib/herb/lint/autofixer.rb`

- [ ] Refactor `apply_fixes` into `apply_ast_fixes` (existing logic)
- [ ] Add `apply_source_fixes(offenses, source)` private method
- [ ] Update `apply` to partition offenses by `autofix_context.source_rule?`
- [ ] Apply AST fixes first, then source fixes on the resulting source string
- [ ] Source fixes call `rule.autofix_source(offense, source)` sequentially
- [ ] Track fixed/unfixed for source fixes
- [ ] Update unit tests
- [ ] Update RBS types

**Processing Flow:**

```ruby
def apply
  fixable, non_fixable = offenses.partition { |o| o.fixable?(unsafe:) }

  ast_fixable, source_fixable = fixable.partition { |o| o.autofix_context.visitor_rule? }

  source, ast_fixed, ast_unfixed = apply_ast_fixes(ast_fixable)
  source, src_fixed, src_unfixed = apply_source_fixes(source_fixable, source)

  AutoFixResult.new(
    source:,
    fixed: ast_fixed + src_fixed,
    unfixed: non_fixable + ast_unfixed + src_unfixed
  )
end
```

**Test Cases:**
- Source-only offenses: fixed correctly via `autofix_source`
- Source offense with content mismatch at offset: skipped (added to unfixed)
- Mixed AST + source offenses: AST applied first, then source
- Source autofix returning `nil`: offense added to unfixed
- No source offenses: existing AST-only behavior unchanged (backward compatible)

---

## Part B: Rule Migration

### Task S.4: Migrate NoExtraNewline to SourceRule

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_extra_newline.rb`

- [ ] Change base class from `Base` to `SourceRule`
- [ ] Rename `check` to `check_source` with signature `(source, context)`
- [ ] Remove `_document` parameter
- [ ] Remove `@source = context.source` (now provided by base class as `source` param and `@source`)
- [ ] Remove private `location_from_offsets` and `position_from_offset` methods (now in `SourceRule` base)
- [ ] Add `self.safe_autofixable?` returning `true`
- [ ] Replace `add_offense` with `add_offense_with_source_autofix` (include `start_offset:` and `end_offset:`)
- [ ] Implement `autofix_source(offense, source)` with offset verification
  - [ ] Read `start_offset` and `end_offset` from `offense.autofix_context`
  - [ ] Verify content at offsets is newlines only (`/\A\n+\z/`)
  - [ ] If valid: return `source[0...start_offset] + source[end_offset..]`
  - [ ] If invalid: return `nil`
- [ ] Update existing tests to use new base class
- [ ] Add autofix-specific tests

**Before (current):**

```ruby
class NoExtraNewline < Base
  def check(_document, context)
    @offenses = []
    @context = context
    @source = context.source
    # ... scan logic ...
    add_offense(message:, location:)
    @offenses
  end

  private
  def location_from_offsets(...)  # will be removed
  def position_from_offset(...)  # will be removed
end
```

**After (migrated):**

```ruby
class NoExtraNewline < SourceRule
  def self.safe_autofixable? = true

  def check_source(source, _context)
    source.scan(/\n{4,}/) do
      # ... offset calculation ...
      add_offense_with_source_autofix(
        message:, location:,
        start_offset: offense_start,
        end_offset: offense_end
      )
    end
  end

  def autofix_source(offense, source)
    ctx = offense.autofix_context
    content = source[ctx.start_offset...ctx.end_offset]
    return nil unless content&.match?(/\A\n+\z/)
    source[0...ctx.start_offset] + source[ctx.end_offset..]
  end
end
```

**Test Cases:**
- Existing detection tests still pass (no behavior change)
- Autofix removes extra newlines correctly
- Autofix with single occurrence
- Autofix with multiple occurrences in same file
- Autofix skips when content at offset has changed (returns nil)
- Autofix handles edge case: extra newlines at end of file

---

### Task S.5: Migrate RequireTrailingNewline from VisitorRule to SourceRule

**Location:** `herb-lint/lib/herb/lint/rules/erb/require_trailing_newline.rb`

The TypeScript reference implementation (`erb-require-trailing-newline.ts`) uses `SourceRule` — it receives the raw source string and checks for trailing newlines directly. The current Ruby implementation uses `VisitorRule` and inspects AST nodes (`visit_document_node`), which is unnecessarily complex for this rule.

- [ ] Change base class from `VisitorRule` to `SourceRule`
- [ ] Replace `visit_document_node` with `check_source(source, context)` that inspects the source string directly
- [ ] Simplify detection: check `source.end_with?("\n")` and `source.end_with?("\n\n")` (matching TypeScript logic)
- [ ] Replace AST-based autofix with `autofix_source(offense, source)` returning `source.rstrip + "\n"`
- [ ] Remove AST node manipulation helpers (`copy_html_text_node`, `replace_node`, `append_trailing_newline_text_node`)
- [ ] Update existing tests

**Reference (TypeScript):**

```typescript
class ERBRequireTrailingNewlineVisitor extends BaseSourceRuleVisitor {
  protected visitSource(source: string): void {
    if (source.length === 0) return
    if (!source.endsWith('\n')) {
      this.addOffense("File must end with trailing newline.", createEndOfFileLocation(source))
    } else if (source.endsWith('\n\n')) {
      this.addOffense("File must end with exactly one trailing newline.", createEndOfFileLocation(source))
    }
  }
}

autofix(_offense, source) { return source.trimEnd() + "\n" }
```

**Test Cases:**
- Empty file: no offense
- File without trailing newline: offense reported
- File with exactly one trailing newline: no offense
- File with multiple trailing newlines: offense reported
- Autofix returns `source.rstrip + "\n"`
- Existing detection tests still pass (no behavior change)

---

## Part C: Integration

### Task S.7: Update Type Annotations and Registry

**Location:** `herb-lint/lib/herb/lint/linter.rb`, `herb-lint/lib/herb/lint/runner.rb`, `herb-lint/lib/herb/lint/rule_registry.rb`

- [ ] Update `Linter` type annotations to include `SourceRule` in rules union type
- [ ] Update `Runner` type annotations to include `SourceRule`
- [ ] Verify `RuleRegistry` can register `SourceRule` subclasses (should work since `SourceRule < Base`)
- [ ] Update RBS signatures for all changed files
- [ ] Run `steep check` to verify type correctness

**Expected Changes:**

```ruby
# linter.rb
attr_reader :rules #: Array[Rules::Base | Rules::VisitorRule | Rules::SourceRule]

# runner.rb
def instantiate_rules #: Array[Rules::Base | Rules::VisitorRule | Rules::SourceRule]
```

**Note:** Since `SourceRule < Base`, the existing `Array[Rules::Base | Rules::VisitorRule]` type already covers `SourceRule` via inheritance. However, making it explicit improves documentation and type safety.

---

### Task S.8: Full Verification

- [ ] Run `cd herb-lint && ./bin/rspec` -- all tests pass
- [ ] Run `cd herb-lint && ./bin/rubocop` -- no offenses
- [ ] Run `cd herb-lint && ./bin/steep check` -- type checking passes
- [ ] Verify existing rules (VisitorRule-based) are unaffected
- [ ] Verify `NoExtraNewline` detection behavior is unchanged
- [ ] Verify `NoExtraNewline` autofix works end-to-end
- [ ] Verify `RequireTrailingNewline` detection behavior is unchanged
- [ ] Verify `RequireTrailingNewline` autofix works end-to-end

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| S.1 | A | Extend AutofixContext with source rule fields |
| S.2 | A | Create SourceRule base class |
| S.3 | A | Extend Autofixer with source phase |
| S.4 | B | Migrate NoExtraNewline to SourceRule with autofix |
| S.5 | B | Migrate RequireTrailingNewline from VisitorRule to SourceRule |
| S.6 | C | Update type annotations and registry |
| S.7 | C | Full verification |

**Total: 7 tasks**

## Future Work

After the Source Rule infrastructure is established:

- **New source rules** can be added by extending `SourceRule` (e.g., file encoding checks, line length limits).
- **LexerRule (token-based rules)** -- The TypeScript reference defines a third rule type `LexerRule` that operates on token streams (`LexResult`) from `Herb.lex()`. Its `check` receives `LexResult` (a token list) and `autofix` returns a corrected `LexResult`. However, **no built-in rules currently use LexerRule** in the TypeScript implementation — all rules are either `ParserRule` or `SourceRule`. LexerRule support can be added if a concrete use case arises, following the same pattern as SourceRule (new base class, unified AutofixContext with token-level fields, Autofixer phase 3).

## Related Documents

- [Autofix Design](../design/herb-lint-autofix-design.md) -- Source Rule autofix design details
- [herb-lint Design](../design/herb-lint-design.md) -- Overall linter architecture
- [Phase 15: Autofix](./phase-15-autofix.md) -- Autofix infrastructure (prerequisite)
- [Phase 12: ERB Rule Expansion](./phase-12-erb-rule-expansion.md) -- ERB rules including NoExtraNewline
