# Phase 15: Autofix

This phase implements the `--fix` / `--fix-unsafely` feature for herb-lint: automatic correction of lint offenses via AST mutation and re-serialization.

**Design document:** [herb-lint-autofix-design.md](../design/herb-lint-autofix-design.md)

**Reference:** TypeScript `@herb-tools/linter` autofix functionality

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| AutofixContext | Bridge between check phase and autofix phase (direct node reference) | Enables offense → fix mapping |
| NodeLocator | Find parent nodes in AST by object identity | Required for parent lookup during AST mutation |
| Autofixer | Orchestrate autofix application per file (reuses lint-phase ParseResult) | Core autofix engine |
| CLI flags | `--fix` and `--fix-unsafely` options | User-facing autofix interface |
| Rule autofix | `autofix` method on fixable rules | Per-rule fix implementation |

## Prerequisites

- Phase 1-7 (MVP) complete
- Phase 14 (herb-printer) complete — `IdentityPrinter` required for AST-to-source serialization
- herb-lint gem available

## Design Principles

1. **AST Node Replacement via Public API** — Create new nodes using public constructors, replace via `Array#[]=` in parent arrays. No `instance_variable_set`.
2. **Whitespace Preservation** — The lint phase already parses with `track_whitespace: true`. The autofix phase reuses the same `ParseResult` (single-parse design).
3. **Single-Parse Design** — The lint phase produces a whitespace-preserving AST. The autofix phase reuses it directly. No re-parsing needed. Offenses carry direct node references via `AutofixContext`.
4. **Two-Phase Application** — AST phase (current rules) + Source phase (future extension).
5. **No Re-run Loop** — Single pass, like the TypeScript reference. Users run multiple times for cascading fixes.

---

## Part A: Autofix Infrastructure

### Task 15.1: AutofixContext, Offense, and LintResult Changes

**Location:** `herb-lint/lib/herb/lint/autofix_context.rb`, `herb-lint/lib/herb/lint/offense.rb`, `herb-lint/lib/herb/lint/lint_result.rb`, `herb-lint/lib/herb/lint/linter.rb`

- [x] Implement `AutofixContext` Data class
  - [x] `node` (`Herb::AST::Node`) — direct reference to the offending AST node
  - [x] `rule_class` (`Class`) — rule class that can fix this offense
- [x] Update `Offense` to accept optional `autofix_context`
  - [x] Add `autofix_context` attribute (default: `nil`)
  - [x] Add `fixable?` method — returns `true` when `autofix_context` is present
- [x] Update `LintResult` to accept optional `parse_result`
  - [x] Add `parse_result` attribute (default: `nil`)
  - [x] `nil` when parsing fails (parse error offenses are reported instead)
- [x] Update `Linter#lint` to include `parse_result` in `LintResult`
- [x] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [x] Add unit tests

**Data Structure:**

```ruby
module Herb
  module Lint
    AutofixContext = Data.define(
      :node,       #: Herb::AST::Node
      :rule_class  #: singleton(Rules::VisitorRule)
    )
  end
end
```

**Test Cases:**
- `AutofixContext` stores node reference and rule class
- `Offense` with `autofix_context` returns `fixable? == true`
- `Offense` without `autofix_context` returns `fixable? == false`
- Backward compatibility: existing offense creation without `autofix_context` still works
- `LintResult` with `parse_result` exposes it via accessor
- `LintResult` without `parse_result` defaults to `nil`

---

### Task 15.2: RuleMethods Autofix Extensions

**Location:** `herb-lint/lib/herb/lint/rules/rule_methods.rb`

- [x] Add `safe_autofixable?` class method (default: `false`)
- [x] Add `unsafe_autofixable?` class method (default: `false`)
- [x] Add `add_offense_with_autofix` instance method
  - [x] Creates `AutofixContext` from the given node and current rule class
  - [x] Delegates to `add_offense` with the context attached
- [x] Add `autofix` instance method (default: returns `false`)
  - [x] Signature: `autofix(node, parse_result) -> bool`
  - [x] Override in fixable rules to perform AST mutation
- [x] Add unit tests

**Interface:**

```ruby
module Herb
  module Lint
    module Rules
      module RuleMethods
        module ClassMethods
          def safe_autofixable? = false
          def unsafe_autofixable? = false
        end

        def add_offense_with_autofix(message:, location:, node:)
          context = AutofixContext.new(
            node: node,
            rule_class: self.class
          )
          add_offense(message:, location:, autofix_context: context)
        end

        def autofix(node, parse_result) = false
      end
    end
  end
end
```

**Test Cases:**
- Default `safe_autofixable?` returns `false`
- Default `unsafe_autofixable?` returns `false`
- `add_offense_with_autofix` creates offense with `AutofixContext`
- Default `autofix` returns `false`
- Subclass can override `safe_autofixable?` to return `true`

---

### Task 15.3: NodeLocator Implementation

**Location:** `herb-lint/lib/herb/lint/node_locator.rb`

With the single-parse design, offenses carry direct node references. `NodeLocator.find` (re-locating by location/type) is no longer needed. Instead, `NodeLocator` provides parent lookup by object identity — autofix methods need the parent node to perform array-based replacement.

- [x] Implement `NodeLocator` class extending `Herb::Visitor`
  - [x] `self.find_parent(parse_result, target_node)` — find the parent of a given node
  - [x] Override `visit_child_nodes` — check identity via `equal?`, delegate traversal to `super`
  - [x] Track `@parent_stack` during traversal
- [x] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [x] Add unit tests

**Matching Logic:**

A node matches when `node.equal?(target_node)` (object identity). Since the autofix phase operates on the same `ParseResult` as the lint phase, the node reference from `AutofixContext` is the same object in the AST.

**Test Cases:**
- `find_parent` returns the parent node for a given child in a simple document
- `find_parent` returns the parent for an attribute node within an element
- `find_parent` returns `nil` when node is not in the tree (stale reference after replacement)
- `find_with_parent` returns `[node, parent]` tuple
- `find_with_parent` returns `nil` when node not found

---

## Part B: Autofixer & Runner Integration

### Task 15.4: AutoFixResult Data Class

**Location:** `herb-lint/lib/herb/lint/auto_fix_result.rb`

- [x] Implement `AutoFixResult` Data class
  - [x] `source` (`String`) — corrected source code
  - [x] `fixed` (`Array[Offense]`) — successfully fixed offenses
  - [x] `unfixed` (`Array[Offense]`) — offenses that could not be fixed
  - [x] `fixed_count` method
  - [x] `unfixed_count` method
- [x] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [x] Add unit tests

**Data Structure:**

```ruby
module Herb
  module Lint
    AutoFixResult = Data.define(
      :source,  #: String
      :fixed,   #: Array[Offense]
      :unfixed  #: Array[Offense]
    ) do
      def fixed_count = fixed.size   #: Integer
      def unfixed_count = unfixed.size #: Integer
    end
  end
end
```

**Test Cases:**
- `fixed_count` returns number of fixed offenses
- `unfixed_count` returns number of unfixed offenses
- Empty result has zero counts

---

### Task 15.5: Autofixer Implementation

**Location:** `herb-lint/lib/herb/lint/autofixer.rb`

The Autofixer receives the `ParseResult` from the lint phase (single-parse design) rather than re-parsing the source. Offenses carry direct node references via `AutofixContext`.

- [x] Implement `Autofixer` class
  - [x] `initialize(parse_result, offenses, fix_unsafely: false)`
  - [x] `apply` → `AutoFixResult`
    - [x] Filter to fixable offenses (`offense.fixable?`)
    - [x] Filter by safety level (`safe_to_apply?`)
    - [x] Call `apply_ast_fixes` for AST-phase fixes
    - [x] Return `AutoFixResult`
  - [x] Private `apply_ast_fixes(offenses)` → `[String, Array[Offense], Array[Offense]]`
    - [x] For each fixable offense: retrieve node from `offense.autofix_context.node`, call `autofix`, track result
    - [x] Serialize via `Herb::Printer::IdentityPrinter.print(@parse_result)`
  - [x] Private `fixable_offenses(offenses)` — filter to offenses with `fixable? == true`
  - [x] Private `safe_to_apply?(offense)` — check safety based on `fix_unsafely` flag
- [x] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [x] Add unit tests

**Safety Model:**

| Rule declares | `--fix` applies? | `--fix-unsafely` applies? |
|---------------|-----------------|--------------------------|
| `safe_autofixable? = true` | Yes | Yes |
| `unsafe_autofixable? = true` | No | Yes |
| Neither (default) | No | No |

**Processing Flow:**

```
Autofixer#apply
  ├── filter fixable offenses
  ├── filter by safety level
  ├── apply_ast_fixes (operates on lint-phase parse_result)
  │   ├── for each offense:
  │   │   ├── offense.autofix_context.node → node (direct reference)
  │   │   ├── rule.new.autofix(node, parse_result) → bool
  │   │   └── track as fixed or unfixed
  │   └── IdentityPrinter.print(parse_result) → new_source
  └── return AutoFixResult
```

**Test Cases:**
- No fixable offenses returns original source
- Single fixable offense applied correctly
- Multiple fixable offenses applied in single pass
- Non-fixable offenses remain in unfixed list
- `--fix` skips unsafe autofixes
- `--fix-unsafely` applies unsafe autofixes
- Stale node reference (replaced by prior autofix) results in unfixed offense
- AutoFixResult contains correct counts

---

### Task 15.6: Runner and CLI Integration

**Location:** `herb-lint/lib/herb/lint/runner.rb`, `herb-lint/lib/herb/lint/cli.rb`

- [x] Update `Runner` constructor to accept `autofix` and `unsafe` options
- [x] Update `Runner#process_file` to apply fixes after linting
  - [x] Create `Autofixer` when fix enabled and fixable offenses exist
  - [x] Write fixed content back to file
  - [x] Report only unfixed offenses
- [x] Add `--fix` CLI option parsing
- [x] Add `--fix-unsafely` CLI option parsing (`--fix-unsafely` implies `--fix`)
- [x] Pass fix options from CLI to Runner
- [x] Add integration tests

**CLI Changes:**

```ruby
opts.on("--fix", "Apply safe automatic fixes") do
  options[:fix] = true
end
opts.on("--fix-unsafely", "Apply all fixes including unsafe ones") do
  options[:fix] = true
  options[:fix_unsafely] = true
end
```

**Runner Changes:**

```ruby
def process_file(file_path)
  source = File.read(file_path)
  result = linter.lint(file_path:, source:)

  if fix && result.parse_result && result.offenses.any?(&:fixable?)
    fix_result = apply_fixes(file_path, result)
    File.write(file_path, fix_result.source) if fix_result.source != source
    # Update result to only include unfixed offenses
  end

  result
end
```

Note: `result.parse_result` is `nil` when parsing fails, so autofix is skipped for files with parse errors.

**Test Cases:**
- `--fix` flag parsed correctly
- `--fix-unsafely` flag implies `--fix`
- Runner applies fixes and writes files
- Runner reports only unfixed offenses after fix
- Exit code reflects remaining unfixed offenses
- Files without fixable offenses are not modified

---

## Part C: Autofix Reporting

### Task 15.7: LintResult and AggregatedResult Extensions

**Location:** `herb-lint/lib/herb/lint/lint_result.rb`, `herb-lint/lib/herb/lint/aggregated_result.rb`, `herb-lint/lib/herb/lint/runner.rb`

**Goal:** Extend result classes to track autofixed offenses and provide count methods for reporting.

- [x] Update `LintResult` to track autofixed offenses
  - [x] Add `autofixed_offenses` attribute (default: `[]`)
  - [x] Add `autofixed_count` method
  - [x] Add `autofixable_count` method (counts offenses with `fixable? == true`)
- [x] Update `AggregatedResult` to aggregate autofix statistics
  - [x] Add `autofixed_count` method (sum of all autofixed offenses)
  - [x] Add `autofixable_count` method (sum of all autofixable offenses)
- [x] Update `Runner#process_file` to preserve autofixed offenses
  - [x] When autofix is applied, store `fix_result.fixed` in `LintResult#autofixed_offenses`
  - [x] Merge `autofixed_offenses` with `unfixed` for reporting (show all offenses)
- [x] Add unit tests

**Test Cases:**
- `LintResult` with autofixed offenses exposes them via `autofixed_offenses`
- `autofixable_count` counts only autofixable offenses
- `autofixed_count` counts only autofixed offenses
- `AggregatedResult` aggregates counts correctly
- `Runner` preserves autofixed offenses when `--fix` is enabled

---

### Task 15.8: SimpleReporter Autofix Support

**Location:** `herb-lint/lib/herb/lint/reporter/simple_reporter.rb`

**Goal:** Display `[Correctable]` label and autofix statistics in SimpleReporter output.

**Reference:** TypeScript `@herb-tools/linter` uses `[Correctable]` label (green) to indicate fixable offenses.

- [x] Update `print_offense` to show `[Correctable]` label
  - [x] Append `[Correctable]` for `offense.fixable?`
  - [x] Use green color if TTY supports it
- [x] Update `format_summary` to show autofix statistics
  - [x] When fixes applied: `"X problems (Y corrected, Z fixable) in N files"`
  - [x] When no fixes applied but fixable exist: `"X problems (Z fixable) in N files"`
  - [x] When no fixable: `"X problems in N files"`
- [x] Add unit tests

**Output Examples:**

**Without `--fix`:**
```
app/views/users/show.html.erb
  3:10  error    Missing alt attribute on img tag  html/img-require-alt  [Correctable]
  5:15  warning  Prefer double quotes for attributes  html/attribute-double-quotes

2 problems (2 fixable) in 1 file
```

**With `--fix` (safe fixes applied):**
```
app/views/users/show.html.erb
  3:10  error    Missing alt attribute on img tag  html/img-require-alt  [Correctable]
  5:15  warning  Prefer double quotes for attributes  html/attribute-double-quotes

2 problems (1 corrected, 1 fixable) in 1 file
```

**Test Cases:**
- `print_offense` appends `[Correctable]` for fixable offenses
- `print_offense` does not append label for non-fixable offenses
- Summary shows "X fixable" when no fixes applied
- Summary shows "Y corrected, Z fixable" when fixes applied
- Summary shows plain format when no fixable offenses

---

### Task 15.9: GithubReporter Autofix Support

**Status:** NOT IMPLEMENTED (TypeScript compatibility)

**Location:** `herb-lint/lib/herb/lint/reporter/github_reporter.rb`

**Decision:** The TypeScript reference implementation does not include `[Correctable]` markers in GitHub Actions annotations. To maintain CLI compatibility with the TypeScript implementation, this feature will not be implemented in the Ruby version.

**Reference:** TypeScript `@herb-tools/linter` GitHub Actions formatter outputs annotations without autocorrectable indicators.

- [x] Verified TypeScript implementation does not show `[Correctable]` suffix
- [x] Decision: Skip implementation for TypeScript compatibility

---

**Note:** JsonReporter does NOT include `correctable` or `corrected` fields in the TypeScript reference implementation. JSON output remains unchanged.

**Note:** The original Task 15.7 (Autofix utility helpers) has been moved to [Phase 16: Rule Autofix Expansion](./phase-16-rule-autofix-expansion.md).

---

## Verification

### Part A: Autofix Infrastructure

```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/autofix_context_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/node_locator_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

### Part B: Autofixer & Runner Integration

```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/autofixer_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/auto_fix_result_spec.rb

# Integration tests
cd herb-lint && ./bin/rspec spec/herb/lint/runner_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/cli_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

### Part C: Autofix Reporting

**Task 15.7:**
```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/lint_result_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/aggregated_result_spec.rb

# Integration tests
cd herb-lint && ./bin/rspec spec/herb/lint/runner_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

**Task 15.8:**
```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/reporter/simple_reporter_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

**Task 15.9:**
```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/reporter/github_reporter_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| 15.1 | A | AutofixContext and Offense changes |
| 15.2 | A | RuleMethods autofix extensions |
| 15.3 | A | NodeLocator implementation |
| 15.4 | B | AutoFixResult Data class |
| 15.5 | B | Autofixer implementation |
| 15.6 | B | Runner and CLI integration |
| 15.7 | C | LintResult and AggregatedResult extensions |
| 15.8 | C | SimpleReporter autofix support |
| 15.9 | C | GithubReporter autofix support (skipped for TypeScript compatibility) |

**Total: 8 tasks (1 skipped for compatibility)**

**Note:** The original Task 15.7 (Autofix utility helpers) and rule-specific autofix implementations have been extracted to [Phase 16: Rule Autofix Expansion](./phase-16-rule-autofix-expansion.md) for better organization and incremental implementation.

## Related Documents

- [Autofix Design](../design/herb-lint-autofix-design.md) — Detailed design document
- [herb-lint Design](../design/herb-lint-design.md) — Overall linter architecture
- [Printer Design](../design/printer-design.md) — IdentityPrinter for AST-to-source serialization
- [Phase 14: herb-printer](./phase-14-herb-printer.md) — Prerequisite phase
- [Phase 16: Rule Autofix Expansion](./phase-16-rule-autofix-expansion.md) — Rule-specific autofix implementations
