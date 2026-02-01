# Phase 15: Autofix

This phase implements the `--fix` / `--fix-unsafely` feature for herb-lint: automatic correction of lint offenses via AST mutation and re-serialization.

**Design document:** [herb-lint-autofix-design.md](../design/herb-lint-autofix-design.md)

**Reference:** TypeScript `@herb-tools/linter` autofix functionality

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| AutofixContext | Bridge between check phase and autofix phase | Enables offense → fix mapping |
| NodeLocator | Find nodes in freshly-parsed AST by location/type | Required for AST mutation after re-parse |
| AutoFixer | Orchestrate autofix application per file | Core autofix engine |
| CLI flags | `--fix` and `--fix-unsafely` options | User-facing autofix interface |
| Rule autofix | `autofix` method on fixable rules | Per-rule fix implementation |

## Prerequisites

- Phase 1-7 (MVP) complete
- Phase 14 (herb-printer) complete — `IdentityPrinter` required for AST-to-source serialization
- herb-lint gem available

## Design Principles

1. **AST Node Replacement via Public API** — Create new nodes using public constructors, replace via `Array#[]=` in parent arrays. No `instance_variable_set`.
2. **Whitespace Preservation** — Always parse with `track_whitespace: true` for lossless round-trip.
3. **Two-Phase Application** — AST phase (current rules) + Source phase (future extension).
4. **No Re-run Loop** — Single pass, like the TypeScript reference. Users run multiple times for cascading fixes.

---

## Part A: Autofix Infrastructure

### Task 15.1: AutofixContext and Offense Changes

**Location:** `herb-lint/lib/herb/lint/autofix_context.rb`, `herb-lint/lib/herb/lint/offense.rb`

- [ ] Implement `AutofixContext` Data class
  - [ ] `node_location` (`Herb::Location`) — location of the target node
  - [ ] `node_type` (`String`) — AST node type (e.g., `"HTMLElementNode"`)
  - [ ] `rule_class` (`Class`) — rule class that can fix this offense
- [ ] Update `Offense` to accept optional `autofix_context`
  - [ ] Add `autofix_context` attribute (default: `nil`)
  - [ ] Add `fixable?` method — returns `true` when `autofix_context` is present
- [ ] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [ ] Add unit tests
- [ ] Generate RBS types

**Data Structure:**

```ruby
module Herb
  module Lint
    AutofixContext = Data.define(
      :node_location, #: Herb::Location
      :node_type,     #: String
      :rule_class     #: singleton(Rules::VisitorRule)
    )
  end
end
```

**Test Cases:**
- `AutofixContext` stores location, type, and rule class
- `Offense` with `autofix_context` returns `fixable? == true`
- `Offense` without `autofix_context` returns `fixable? == false`
- Backward compatibility: existing offense creation without `autofix_context` still works

---

### Task 15.2: RuleMethods Autofix Extensions

**Location:** `herb-lint/lib/herb/lint/rules/rule_methods.rb`

- [ ] Add `autocorrectable?` class method (default: `false`)
- [ ] Add `unsafe_autocorrectable?` class method (default: `false`)
- [ ] Add `add_offense_with_autofix` instance method
  - [ ] Creates `AutofixContext` from the given node and current rule class
  - [ ] Delegates to `add_offense` with the context attached
- [ ] Add `autofix` instance method (default: returns `false`)
  - [ ] Signature: `autofix(node, parse_result) -> bool`
  - [ ] Override in fixable rules to perform AST mutation
- [ ] Add unit tests
- [ ] Generate RBS types

**Interface:**

```ruby
module Herb
  module Lint
    module Rules
      module RuleMethods
        module ClassMethods
          def autocorrectable? = false
          def unsafe_autocorrectable? = false
        end

        def add_offense_with_autofix(message:, location:, node:)
          context = AutofixContext.new(
            node_location: node.location,
            node_type: node.class.name.split("::").last,
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
- Default `autocorrectable?` returns `false`
- Default `unsafe_autocorrectable?` returns `false`
- `add_offense_with_autofix` creates offense with `AutofixContext`
- Default `autofix` returns `false`
- Subclass can override `autocorrectable?` to return `true`

---

### Task 15.3: NodeLocator Implementation

**Location:** `herb-lint/lib/herb/lint/node_locator.rb`

- [ ] Implement `NodeLocator` class extending `Herb::Visitor`
  - [ ] `self.find(parse_result, location, node_type)` — find a node matching location and type
  - [ ] `self.find_with_parent(parse_result, location, node_type)` — find node and its parent
  - [ ] Private `match?(node)` — compare type + location (start line/column, end line/column)
  - [ ] Track `@parent_stack` during traversal
- [ ] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [ ] Add unit tests
- [ ] Generate RBS types

**Matching Logic:**

A node matches when:
1. `node.class.name` ends with `node_type`
2. `node.location.start.line == target.start.line`
3. `node.location.start.column == target.start.column`
4. `node.location.end.line == target.end.line`
5. `node.location.end.column == target.end.column`

**Test Cases:**
- Find an `HTMLElementNode` by location in a simple document
- Find an `HTMLAttributeNode` by location in a document with attributes
- Return `nil` when no node matches the location
- Return `nil` when location matches but type does not
- `find_with_parent` returns `[node, parent]` tuple
- `find_with_parent` returns `nil` when node not found

---

## Part B: AutoFixer & Runner Integration

### Task 15.4: AutoFixResult Data Class

**Location:** `herb-lint/lib/herb/lint/auto_fix_result.rb`

- [ ] Implement `AutoFixResult` Data class
  - [ ] `source` (`String`) — corrected source code
  - [ ] `fixed` (`Array[Offense]`) — successfully fixed offenses
  - [ ] `unfixed` (`Array[Offense]`) — offenses that could not be fixed
  - [ ] `fixed_count` method
  - [ ] `unfixed_count` method
- [ ] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [ ] Add unit tests
- [ ] Generate RBS types

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

### Task 15.5: AutoFixer Implementation

**Location:** `herb-lint/lib/herb/lint/auto_fixer.rb`

- [ ] Implement `AutoFixer` class
  - [ ] `initialize(source, offenses, fix_unsafely: false)`
  - [ ] `apply` → `AutoFixResult`
    - [ ] Filter to fixable offenses (`offense.fixable?`)
    - [ ] Filter by safety level (`safe_to_apply?`)
    - [ ] Call `apply_ast_fixes` for AST-phase fixes
    - [ ] Return `AutoFixResult`
  - [ ] Private `apply_ast_fixes(source, offenses)` → `[String, Array[Offense], Array[Offense]]`
    - [ ] Parse with `Herb.parse(source, track_whitespace: true)`
    - [ ] For each fixable offense: locate node via `NodeLocator`, call `autofix`, track result
    - [ ] Serialize via `Herb::Printer::IdentityPrinter.print(parse_result)`
  - [ ] Private `fixable_offenses(offenses)` — filter to offenses with `fixable? == true`
  - [ ] Private `safe_to_apply?(offense)` — check safety based on `fix_unsafely` flag
- [ ] Add `require_relative` to `herb-lint/lib/herb/lint.rb`
- [ ] Add unit tests
- [ ] Generate RBS types

**Safety Model:**

| Rule declares | `--fix` applies? | `--fix-unsafely` applies? |
|---------------|-----------------|--------------------------|
| `autocorrectable? = true` | Yes | Yes |
| `unsafe_autocorrectable? = true` | No | Yes |
| Neither (default) | No | No |

**Processing Flow:**

```
AutoFixer#apply
  ├── filter fixable offenses
  ├── filter by safety level
  ├── apply_ast_fixes
  │   ├── Herb.parse(source, track_whitespace: true)
  │   ├── for each offense:
  │   │   ├── NodeLocator.find(parse_result, location, type) → node
  │   │   ├── skip if node not found → unfixed
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
- Node not found results in unfixed offense
- AutoFixResult contains correct counts

---

### Task 15.6: Runner and CLI Integration

**Location:** `herb-lint/lib/herb/lint/runner.rb`, `herb-lint/lib/herb/lint/cli.rb`

- [ ] Update `Runner` constructor to accept `fix` and `fix_unsafely` options
- [ ] Update `Runner#process_file` to apply fixes after linting
  - [ ] Create `AutoFixer` when fix enabled and fixable offenses exist
  - [ ] Write fixed content back to file
  - [ ] Report only unfixed offenses
- [ ] Add `--fix` CLI option parsing
- [ ] Add `--fix-unsafely` CLI option parsing (`--fix-unsafely` implies `--fix`)
- [ ] Pass fix options from CLI to Runner
- [ ] Add integration tests
- [ ] Generate RBS types

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

  if fix && result.offenses.any?(&:fixable?)
    fix_result = apply_fixes(file_path, source, result.offenses)
    File.write(file_path, fix_result.source) if fix_result.source != source
    # Update result to only include unfixed offenses
  end

  result
end
```

**Test Cases:**
- `--fix` flag parsed correctly
- `--fix-unsafely` flag implies `--fix`
- Runner applies fixes and writes files
- Runner reports only unfixed offenses after fix
- Exit code reflects remaining unfixed offenses
- Files without fixable offenses are not modified

---

## Part C: Rule Autofix Methods

### Task 15.7: Autofix Utility Helpers

**Location:** `herb-lint/lib/herb/lint/autofix_helpers.rb`

- [ ] Implement `AutofixHelpers` module (included in fixable rules)
  - [ ] `parent_array_for(parent, node)` — find the mutable array containing node in parent
    - [ ] Check `parent.children` first
    - [ ] Check `parent.body` as fallback
    - [ ] Return `nil` if not found
  - [ ] `find_parent(parse_result, node)` — convenience wrapper around `NodeLocator.find_with_parent`
- [ ] Add unit tests
- [ ] Generate RBS types

**Interface:**

```ruby
module Herb
  module Lint
    module AutofixHelpers
      def parent_array_for(parent, node)
        if parent.respond_to?(:children) && parent.children.include?(node)
          parent.children
        elsif parent.respond_to?(:body) && parent.body.is_a?(Array) && parent.body.include?(node)
          parent.body
        end
      end
    end
  end
end
```

**Test Cases:**
- Returns `children` array when node is in parent's children
- Returns `body` array when node is in parent's body
- Returns `nil` when node is not in any parent array

---

### Task 15.8: Add Autofix to Existing Rules

Update existing fixable rules to declare `autocorrectable?` and implement `autofix`:

- [ ] Identify which existing rules are autofixable (per TypeScript reference)
- [ ] For each fixable rule:
  - [ ] Add `def self.autocorrectable? = true`
  - [ ] Change `add_offense` to `add_offense_with_autofix` in detection
  - [ ] Implement `autofix(node, parse_result)` method
  - [ ] Add autofix unit tests

**Node Replacement Patterns:**

| Pattern | When | Example |
|---------|------|---------|
| Replace in children array | Attribute-level changes | Boolean attribute fix, quote change |
| Reconstruct to array boundary | Element-level changes | Tag name lowercase |
| Children array modification | Add/remove children | Self-closing removal |

**Example — Tag name lowercase autofix:**

```ruby
class HtmlTagNameLowercase < VisitorRule
  def self.autocorrectable? = true

  def autofix(node, parse_result)
    result = NodeLocator.find_with_parent(parse_result, node.location, "HTMLElementNode")
    return false unless result

    found_node, parent = result
    new_element = build_lowercase_element(found_node)

    parent_array = parent_array_for(parent, found_node)
    return false unless parent_array

    idx = parent_array.index(found_node)
    return false unless idx

    parent_array[idx] = new_element
    true
  end
end
```

**Test Cases (per fixable rule):**
- Autofix produces correct output source
- `autocorrectable?` returns `true`
- `add_offense_with_autofix` creates fixable offense
- Round-trip: source → parse → detect → autofix → print → expected source

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

### Part B: AutoFixer & Runner Integration

```bash
# Unit tests
cd herb-lint && ./bin/rspec spec/herb/lint/auto_fixer_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/auto_fix_result_spec.rb

# Integration tests
cd herb-lint && ./bin/rspec spec/herb/lint/runner_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/cli_spec.rb

# Type check
cd herb-lint && ./bin/steep check
```

### Part C: Rule Autofix

```bash
# Rule autofix tests
cd herb-lint && ./bin/rspec spec/herb/lint/rules/ --tag autofix

# Type check
cd herb-lint && ./bin/steep check
```

**Manual Test:**

```erb
<%# test.html.erb %>
<DIV class='foo'>hello</DIV>
```

```bash
herb-lint --fix test.html.erb
cat test.html.erb
# Expected: <div class="foo">hello</div>
```

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| 15.1 | A | AutofixContext and Offense changes |
| 15.2 | A | RuleMethods autofix extensions |
| 15.3 | A | NodeLocator implementation |
| 15.4 | B | AutoFixResult Data class |
| 15.5 | B | AutoFixer implementation |
| 15.6 | B | Runner and CLI integration |
| 15.7 | C | Autofix utility helpers |
| 15.8 | C | Add autofix to existing rules |

**Total: 8 tasks**

## Related Documents

- [Autofix Design](../design/herb-lint-autofix-design.md) — Detailed design document
- [herb-lint Design](../design/herb-lint-design.md) — Overall linter architecture
- [Printer Design](../design/printer-design.md) — IdentityPrinter for AST-to-source serialization
- [Phase 14: herb-printer](./phase-14-herb-printer.md) — Prerequisite phase
