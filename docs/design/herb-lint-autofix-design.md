# herb-lint Autofix Detailed Design

Detailed design document for the herb-lint `--fix` / `--fix-unsafely` feature: automatic correction of lint offenses.

## Overview

The autofix feature applies automatic corrections to ERB templates by mutating the AST and re-serializing it via `IdentityPrinter`. When a fixable rule detects an offense, it also provides an `autofix` method that creates replacement AST nodes. The `AutoFixer` orchestrates autofix application: it receives the `ParseResult` from the lint phase, invokes each rule's `autofix` with the offending node (stored as a direct reference in the offense), and serializes the modified AST back to source code.

This design follows the TypeScript reference implementation in `@herb-tools/linter`, which uses the same AST mutation + IdentityPrinter approach.

### Single-Parse Design

The linting phase already parses with `track_whitespace: true`, producing an AST suitable for lossless round-trip serialization. The autofix phase reuses this same `ParseResult` rather than re-parsing the source. This eliminates the need to relocate nodes by location after re-parsing — offenses carry direct references to the original AST nodes detected during linting.

### Two Rule Categories for Autofix

Rules fall into two categories based on how they analyze and fix code:

| Category | Base Class | Check Input | Autofix Input | Autofix Output | Use Case |
|----------|-----------|-------------|---------------|----------------|----------|
| **Visitor Rule** | `VisitorRule` | AST (`ParseResult`) | AST node + `ParseResult` | `bool` (AST mutated in-place) | Semantic analysis, node structure |
| **Source Rule** | `SourceRule` | Source string | Offense + source string | `String?` (corrected source) | Text patterns, file-level formatting |

**Visitor Rules** traverse the AST via the visitor pattern, detect offenses on specific nodes, and fix them by mutating the AST. The corrected source is obtained by serializing the modified AST via `IdentityPrinter`.

**Source Rules** operate on raw source strings using regex or string scanning. They detect offenses by byte offset and fix them by returning a corrected source string. No AST manipulation is involved.

### Future: Lexer Rule (Token-Based)

The TypeScript reference defines a third rule type — `LexerRule` — that operates on token streams (`LexResult`) from `Herb.lex()`:

| Category | Base Class | Check Input | Autofix Input | Autofix Output | Use Case |
|----------|-----------|-------------|---------------|----------------|----------|
| **Lexer Rule** | `LexerRule` | `LexResult` (tokens) | Offense + `LexResult` | `LexResult?` (corrected tokens) | Token-level validation |

`LexResult` contains a `TokenList` (array of `Token` objects with `value`, `type`, `range`, `location`). Lexer Rules analyze token sequences without requiring full AST parsing.

**Current status:** The TypeScript implementation defines `LexerRule` and includes infrastructure support (type guards, dispatch in `Linter.autofix()`), but **no built-in rules use it**. All existing rules are either `ParserRule` (→ `VisitorRule` in Ruby) or `SourceRule`. The Ruby implementation does not implement `LexerRule` at this time. If a concrete use case arises, it can be introduced following the same pattern as `SourceRule`:

1. New `LexerRule` base class with `check_tokens(lex_result, context)` delegation
2. Unified `AutofixContext` extended with token-level fields
3. `AutoFixer` phase 3 for token-based fixes

## Reference Implementation

The TypeScript reference is `@herb-tools/linter` in the [herb repository](https://github.com/marcoroth/herb):

| TypeScript | Ruby |
|-----------|------|
| `Linter.autofix()` | `Herb::Lint::AutoFixer` |
| `IdentityPrinter` (in `@herb-tools/printer`) | `Herb::Printer::IdentityPrinter` (in herb-printer gem) |
| `findNodeByLocation()` | `Herb::Lint::NodeLocator` (parent lookup only; node re-finding not needed) |
| `Mutable<T>` (type-level readonly removal) | Not needed (node replacement via public constructors) |
| `autofixContext` on offense | `autofix_context` on `Offense` |
| `static autofixable = true` on rule | `self.safe_autofixable?` on rule class |
| `static unsafeAutocorrectable = true` on rule | `self.unsafe_autofixable?` on rule class |

## Design Principles

### AST Node Replacement via Public API

Herb gem AST nodes use `attr_reader` (no setters). Instead of bypassing this with `instance_variable_set`, autofixes create new nodes using public constructors (`Node.new(...)`) and replace references in parent arrays (`Array#[]=`). This ensures compatibility with future herb gem versions.

**Replacement pattern:** bottom-up node reconstruction from the changed property up to the nearest mutable array boundary.

```
Token.new(...)                         # new leaf
  -> HTMLOpenTagNode.new(..., token, ...)  # reconstruct intermediate
    -> HTMLElementNode.new(..., open_tag, ...)  # reconstruct up to array boundary
      -> document.children[i] = new_element     # replace via Array#[]=
```

### Whitespace Preservation

`Herb.parse(source, track_whitespace: true)` includes `WhitespaceNode` children in the AST. This is required for lossless round-trip serialization via `IdentityPrinter`. The linting phase always parses with this option, and the autofix phase reuses the same `ParseResult`.

### Two-Phase Autofix Application

Following the TypeScript reference, autofixes are applied in two phases:

1. **AST phase**: Rules that operate on AST nodes (`VisitorRule`). All AST autofixes operate on the `ParseResult` from the lint phase; each autofix creates replacement nodes and substitutes them in the tree. After all AST autofixes, `IdentityPrinter` serializes the modified AST back to source.
2. **Source phase**: Rules that operate on raw source strings (`SourceRule`). Each offense carries byte offsets (`start_offset`, `end_offset`) recorded during the check phase. During autofix, the rule verifies that the content at the recorded offsets still matches the expected pattern. If the content has shifted due to a prior fix, the rule returns `nil` and the offense is added to the unfixed list — **offsets are never recalculated**.

This two-phase ordering is important: AST fixes are applied first and serialized to a source string, then source fixes operate on that resulting string.

## CLI Flags

| Flag | Description |
|------|-------------|
| `--fix` | Apply safe autofixes (rules where `safe_autofixable?` is true) |
| `--fix-unsafely` | Also apply unsafe autofixes (rules where `unsafe_autofixable?` is true); implies `--fix` |

## Processing Flow

```
CLI#run
  ├── parse_options (--fix, --fix-unsafely)
  │
  └── Runner#run(files)
      └── for each file:
          ├── source = File.read(file_path)
          │
          ├── Linter#lint(file_path:, source:)
          │   ├── Herb.parse(source, track_whitespace: true) → parse_result
          │   └── LintResult (offenses + parse_result)
          │
          ├── if fix enabled AND fixable offenses exist:
          │   ├── AutoFixer.new(parse_result, offenses, fix_unsafely:)
          │   ├── fix_result = auto_fixer.apply
          │   │   ├── Phase 1: AST autofixes (reuses parse_result from lint phase)
          │   │   │   ├── for each fixable offense:
          │   │   │   │   ├── offense.autofix_context.node → node (direct reference)
          │   │   │   │   ├── rule.autofix(node, parse_result) → bool
          │   │   │   │   └── track fixed vs unfixed
          │   │   │   └── IdentityPrinter.print(parse_result) → new_source
          │   │   │
          │   │   └── Phase 2: Source autofixes
          │   │       ├── Partition fixable offenses: source_rule? vs visitor_rule?
          │   │       ├── for each source offense:
          │   │       │   ├── offense.autofix_context.{start_offset, end_offset}
          │   │       │   ├── rule.autofix_source(offense, current_source)
          │   │       │   │   ├── Verify content at offset matches expected pattern
          │   │       │   │   ├── If match: apply fix, return corrected source
          │   │       │   │   └── If mismatch: return nil (skip, add to unfixed)
          │   │       │   └── current_source = corrected_source
          │   │       └── Return final source
          │   │
          │   ├── File.write(file_path, fix_result.source)
          │   └── report unfixed offenses only
          │
          └── else: report all offenses
```

## Component Details

### Changes to Existing Components

#### Herb::Lint::Offense

Add `autofix_context` to carry data from check phase to autofix phase. The context holds a direct reference to the offending AST node, enabling the autofix phase to operate on the same node without re-parsing.

```rbs
class Herb::Lint::Offense
  attr_reader rule_name: String
  attr_reader message: String
  attr_reader severity: String
  attr_reader location: Herb::Location
  attr_reader autofix_context: AutofixContext?    # NEW

  def initialize: (
    rule_name: String,
    message: String,
    severity: String,
    location: Herb::Location,
    ?autofix_context: AutofixContext?
  ) -> void

  def fixable?: () -> bool   # true when autofix_context is present
  def line: () -> Integer
  def column: () -> Integer
end
```

#### Herb::Lint::AutofixContext

Data class bridging the check phase and autofix phase. Uses a unified structure for both Visitor Rules and Source Rules. The rule type is determined by which optional fields are present:

- **Visitor Rule**: `node` is set, offsets are `nil`
- **Source Rule**: `start_offset` and `end_offset` are set, `node` is `nil`

```rbs
class Herb::Lint::AutofixContext
  attr_reader rule_class: singleton(Rules::VisitorRule) | singleton(Rules::SourceRule)
  attr_reader node: Herb::AST::Node?             # Visitor Rule: direct reference to offending node
  attr_reader start_offset: Integer?              # Source Rule: byte offset of offense start
  attr_reader end_offset: Integer?                # Source Rule: byte offset of offense end

  def initialize: (
    rule_class: singleton(Rules::VisitorRule) | singleton(Rules::SourceRule),
    ?node: Herb::AST::Node?,
    ?start_offset: Integer?,
    ?end_offset: Integer?
  ) -> void

  # Returns true when offsets are present (Source Rule offense)
  def source_rule?: () -> bool

  # Returns true when node is present (Visitor Rule offense)
  def visitor_rule?: () -> bool

  # Returns true when the rule can autocorrect this offense.
  def autofixable?: (?unsafe: bool) -> bool
end
```

**Type discrimination by field presence:**

```ruby
# Visitor Rule creates context with node:
AutofixContext.new(rule_class: self.class, node: some_node)

# Source Rule creates context with offsets:
AutofixContext.new(rule_class: self.class, start_offset: 42, end_offset: 50)

# AutoFixer checks which type:
if context.source_rule?   # start_offset present
  rule.autofix_source(offense, source)
else                       # node present
  rule.autofix(context.node, parse_result)
end
```

#### Herb::Lint::Rules::RuleMethods

Add autofix-related class methods and an `add_offense` overload that accepts autofix context.

```rbs
module Herb::Lint::Rules::RuleMethods
  module ClassMethods
    # Existing methods...
    def rule_name: () -> String
    def description: () -> String
    def default_severity: () -> String

    # NEW: whether the rule provides safe autofix
    def safe_autofixable?: () -> bool    # default: false

    # NEW: whether the rule provides unsafe autofix
    def unsafe_autofixable?: () -> bool    # default: false
  end

  # Existing: add_offense without autofix
  def add_offense: (message: String, location: Herb::Location) -> void

  # NEW: add_offense with autofix context
  def add_offense_with_autofix: (
    message: String,
    location: Herb::Location,
    node: Herb::AST::Node
  ) -> void

  # NEW: autofix method (override in fixable rules)
  # Receives the original node (direct reference from AutofixContext) and the parse_result.
  # Modifies the AST by replacing nodes in parent arrays.
  # Returns true if the fix was applied, false otherwise.
  def autofix: (Herb::AST::Node node, Herb::ParseResult parse_result) -> bool
end
```

`add_offense_with_autofix` creates an `Offense` with an `AutofixContext` populated from the given node and the current rule class. Visitor Rules that are fixable call this method instead of `add_offense`.

#### Source Rule Additions to RuleMethods

```rbs
module Herb::Lint::Rules::RuleMethods
  # NEW: add_offense with source autofix context (byte offsets)
  def add_offense_with_source_autofix: (
    message: String,
    location: Herb::Location,
    start_offset: Integer,
    end_offset: Integer
  ) -> void

  # NEW: source-based autofix method (override in fixable Source Rules)
  # Receives the offense (with recorded offsets) and current source string.
  # Returns corrected source string, or nil if fix cannot be applied.
  def autofix_source: (Herb::Lint::Offense offense, String source) -> String?
end
```

`add_offense_with_source_autofix` creates an `AutofixContext` with `start_offset` and `end_offset` (no node). Source Rules that are fixable call this method.

#### Herb::Lint::LintResult

Add `parse_result` to carry the parsed AST through to the autofix phase. This enables the single-parse design where the autofix phase reuses the AST from linting.

```rbs
class Herb::Lint::LintResult
  attr_reader file_path: String
  attr_reader offenses: Array[Offense]
  attr_reader source: String
  attr_reader ignored_count: Integer
  attr_reader parse_result: Herb::ParseResult?    # NEW

  def initialize: (
    file_path: String,
    offenses: Array[Offense],
    source: String,
    ?ignored_count: Integer,
    ?parse_result: Herb::ParseResult?
  ) -> void
end
```

`parse_result` is `nil` when parsing fails (parse error offenses are reported instead).

#### Herb::Lint::Runner

Add `fix` and `fix_unsafely` options. After linting, apply fixes and write back to disk.

```rbs
class Herb::Lint::Runner
  attr_reader config: Herb::Config::LinterConfig
  attr_reader fix: bool               # NEW
  attr_reader fix_unsafely: bool       # NEW
  attr_reader ignore_disable_comments: bool

  def initialize: (
    Herb::Config::LinterConfig,
    ?fix: bool,
    ?fix_unsafely: bool,
    ?ignore_disable_comments: bool
  ) -> void

  def run: (?Array[String] paths) -> AggregatedResult

  private

  def process_file: (String file_path) -> LintResult
  def apply_fixes: (String file_path, LintResult lint_result) -> AutoFixResult   # NEW
end
```

### New Components

#### Herb::Lint::AutoFixer

Orchestrates autofix application for a single file. This is the core new component. It receives the `ParseResult` from the lint phase (single-parse design) and applies fixes to the same AST.

```rbs
class Herb::Lint::AutoFixer
  @parse_result: Herb::ParseResult
  @offenses: Array[Offense]
  @fix_unsafely: bool

  def initialize: (
    Herb::ParseResult parse_result,
    Array[Offense] offenses,
    ?fix_unsafely: bool
  ) -> void

  def apply: () -> AutoFixResult

  private

  def apply_ast_fixes: (Array[Offense] offenses) -> [String, Array[Offense], Array[Offense]]
  def fixable_offenses: (Array[Offense] offenses) -> Array[Offense]
  def safe_to_apply?: (Offense offense) -> bool
end
```

**`apply` method processing:**

1. Filter offenses to those that are fixable (`offense.fixable?`)
2. Filter by safety level (`safe_to_apply?` checks `safe_autofixable?` vs `unsafe_autofixable?` based on `fix_unsafely` flag)
3. Call `apply_ast_fixes` for AST-phase autofixes
4. Return `AutoFixResult` with corrected source and categorized offenses

**`apply_ast_fixes` method processing:**

1. For each fixable offense:
   a. Retrieve the offending node directly from `offense.autofix_context.node`
   b. Call `offense.autofix_context.rule_class.new.autofix(node, @parse_result)`
   c. Track as fixed or unfixed based on return value
2. Serialize modified AST via `Herb::Printer::IdentityPrinter.print(@parse_result)`
3. Return `[new_source, fixed_offenses, unfixed_offenses]`

#### Herb::Lint::AutoFixResult

Result of autofix application for a single file.

```rbs
class Herb::Lint::AutoFixResult
  attr_reader source: String              # corrected source code
  attr_reader fixed: Array[Offense]       # successfully fixed offenses
  attr_reader unfixed: Array[Offense]     # could not be fixed

  def initialize: (
    source: String,
    fixed: Array[Offense],
    unfixed: Array[Offense]
  ) -> void

  def fixed_count: () -> Integer
  def unfixed_count: () -> Integer
end
```

#### Herb::Lint::NodeLocator

Utility for finding nodes and their parents in an AST. With the single-parse design, offenses carry direct node references, so `NodeLocator.find` is no longer needed for re-locating nodes. However, `find_parent` remains essential — autofix methods need to find the parent node to perform array-based replacement.

```rbs
class Herb::Lint::NodeLocator < Herb::Visitor
  # Find the parent of a given node in the AST.
  # The parent is the node whose children/body array contains the target.
  def self.find_parent: (
    Herb::ParseResult parse_result,
    Herb::AST::Node target_node
  ) -> Herb::AST::Node?

  # Find a node and its parent (the node whose children/body array contains it).
  # Uses object identity (equal?) to match the target node.
  def self.find_with_parent: (
    Herb::ParseResult parse_result,
    Herb::AST::Node target_node
  ) -> [Herb::AST::Node, Herb::AST::Node]?

  private

  @target_node: Herb::AST::Node
  @found_parent: Herb::AST::Node?
  @parent_stack: Array[Herb::AST::Node]

  def match?: (Herb::AST::Node node) -> bool
end
```

**Matching logic:** A node matches when `node.equal?(target_node)` (object identity). Since the autofix phase operates on the same `ParseResult` as the lint phase, the node reference from the offense is the same object in the AST. This is simpler and more reliable than the location-based matching used in the TypeScript reference (which requires re-parsing).

## Node Replacement Patterns

Autofixes create new nodes and replace references in parent arrays. The replacement level depends on what property changes.

### Pattern 1: Replace in children array (attribute-level autofixes)

When the changed property is on a node that appears in a parent's `children` array, replace directly.

```
open_tag.children[i] = new_attribute_node
```

**Applicable to:** boolean attribute removal, quote addition/change, attribute equals spacing.

**Example -- Boolean attribute autofix (`disabled="disabled"` → `disabled`):**

```ruby
# node: HTMLAttributeNode (direct reference from AutofixContext)
# parent: HTMLOpenTagNode (from NodeLocator.find_parent)
new_attr = Herb::AST::HTMLAttributeNode.new(
  node.type, node.location, node.errors,
  node.name,  # keep name
  nil,         # remove equals
  nil          # remove value
)
idx = parent.children.index(node)
parent.children[idx] = new_attr
```

### Pattern 2: Reconstruct to array boundary (element-level autofixes)

When the changed property is NOT in an array (e.g., `open_tag.tag_name`, `open_tag.tag_closing`), reconstruct intermediate nodes up to the nearest parent array.

```
Token.new(...)
  -> HTMLOpenTagNode.new(...)
    -> HTMLElementNode.new(...)
      -> grandparent.children[i] = new_element   (or grandparent.body[i] = ...)
```

**Applicable to:** tag name lowercase, self-closing removal.

**Example -- Tag name lowercase (`<DIV>` → `<div>`):**

```ruby
# node: HTMLElementNode
# parent: DocumentNode (children is the array)
old_ot = node.open_tag
new_ot_name = Herb::Token.new(
  old_ot.tag_name.value.downcase,
  old_ot.tag_name.range, old_ot.tag_name.location, old_ot.tag_name.type
)
new_ot = Herb::AST::HTMLOpenTagNode.new(
  old_ot.type, old_ot.location, old_ot.errors,
  old_ot.tag_opening, new_ot_name, old_ot.tag_closing,
  old_ot.children, old_ot.is_void
)

# Similarly reconstruct close_tag if present
new_ct = reconstruct_close_tag(node.close_tag)

new_element = Herb::AST::HTMLElementNode.new(
  node.type, node.location, node.errors,
  new_ot, new_ot_name, node.body, new_ct, node.is_void, node.source
)

idx = parent.children.index(node)
parent.children[idx] = new_element
```

### Pattern 3: Children array modification (add/remove children)

When autofixing requires adding or removing children from an array, use `Array` methods directly.

```
open_tag.children.reject! { |c| ... }   # remove
open_tag.children << new_node             # add
```

**Applicable to:** self-closing autofix (remove trailing whitespace before `/>` when changing to `>`).

## Autofix Rule Implementation

### Rule Declaration

Fixable rules declare `safe_autofixable?` and implement `autofix`:

```ruby
class HtmlTagNameLowercase < VisitorRule
  def self.rule_name = "html-tag-name-lowercase"
  def self.description = "Enforce lowercase tag names"
  def self.default_severity = "warning"
  def self.safe_autofixable? = true          # NEW

  # Detection (existing pattern)
  def visit_html_element_node(node)
    if uppercase_tag?(node)
      add_offense_with_autofix(            # NEW: use autofix variant
        message: "Tag name '#{node.tag_name.value}' should be lowercase",
        location: node.location,
        node: node                         # NEW: pass node for autofix context
      )
    end
    super
  end

  # Fix (NEW)
  # node: direct reference from AutofixContext (same object as detected during linting)
  # parse_result: same ParseResult from the lint phase (single-parse design)
  def autofix(node, parse_result)
    parent = NodeLocator.find_parent(parse_result, node)
    return false unless parent

    new_element = build_lowercase_element(node)

    parent_array = parent_array_for(parent, node)
    return false unless parent_array

    idx = parent_array.index(node)
    return false unless idx

    parent_array[idx] = new_element
    true
  end

  private

  def build_lowercase_element(node)
    # ... construct new element with lowercased tag names
  end
end
```

### Unsafe Autofix

Rules with potentially behavior-changing fixes use `unsafe_autofixable?`:

```ruby
class ErbStrictLocalsRequired < VisitorRule
  def self.safe_autofixable? = false
  def self.unsafe_autofixable? = true    # only applied with --fix-unsafely

  def autofix(node, parse_result)
    # ...
  end
end
```

## Utility Helpers

### parent_array_for

Common helper to find which mutable array a node belongs to in its parent:

```ruby
# Returns the Array that contains `node` within `parent`, or nil.
def parent_array_for(parent, node)
  if parent.respond_to?(:children) && parent.children.include?(node)
    parent.children
  elsif parent.respond_to?(:body) && parent.body.is_a?(Array) && parent.body.include?(node)
    parent.body
  end
end
```

This is provided by the `AutoFixer` or a shared module, accessible to rule `autofix` methods.

## Safety Model

| Rule declares | `--fix` applies? | `--fix-unsafely` applies? |
|---------------|-----------------|--------------------------|
| `safe_autofixable? = true` | Yes | Yes |
| `unsafe_autofixable? = true` | No | Yes |
| Neither (default) | No | No |

`--fix-unsafely` implies `--fix`. Both safe and unsafe autofixes are applied when `--fix-unsafely` is used.

## Dependencies

The autofix feature depends on:

| Dependency | Purpose |
|-----------|---------|
| `herb` gem | `Herb.parse(source, track_whitespace: true)` for whitespace-preserving AST |
| `herb-printer` gem | `Herb::Printer::IdentityPrinter.print(parse_result)` for AST-to-source serialization |
| `herb-lint` (existing) | Rule infrastructure, Offense, Runner, CLI |

**Implementation order:** herb-printer must be implemented before the autofix feature, since `IdentityPrinter` is required for AST-to-source serialization.

## Conflict Handling

Following the TypeScript reference, there is no explicit conflict resolution mechanism. Conflicts are avoided by design:

1. **AST autofixes target distinct nodes.** Each offense references a different node via its direct `AutofixContext.node` reference.
2. **Stale reference = skip.** If a prior autofix replaces a node (creating a new object), `NodeLocator.find_parent` will not find the original node reference in the tree, and the autofix returns `false`. The offense is added to the unfixed list.
3. **No re-run loop.** Unlike RuboCop, the TypeScript reference does not re-run after autofixing. A single pass is applied. Users can run `herb-lint --fix` multiple times if cascading autofixes are needed.

## Testing Strategy

### Unit Tests -- AutoFixer

- Verify autofix application produces correct source
- Verify fixable offenses are applied, non-fixable are skipped
- Verify `--fix` skips unsafe autofixes, `--fix-unsafely` applies them
- Verify stale node reference (replaced by prior autofix) results in unfixed offense

### Unit Tests -- NodeLocator

- Verify `find_parent` returns parent node for a given child
- Verify `nil` returned when node not in the tree (stale reference)
- Verify `find_with_parent` returns `[node, parent]` tuple

### Unit Tests -- Rule autofix

For each fixable rule, test the autofix method:

```ruby
RSpec.describe Herb::Lint::Rules::HtmlTagNameLowercase do
  describe "#autofix" do
    it "lowercases the tag name" do
      source = "<DIV>hello</DIV>"
      parse_result = Herb.parse(source, track_whitespace: true)
      # ... locate node, call autofix, print result
      expect(fixed_source).to eq("<div>hello</div>")
    end
  end
end
```

### Integration Tests -- CLI

- `herb-lint --fix` modifies files and reports remaining offenses
- `herb-lint --fix-unsafely` applies unsafe autofixes
- Exit code reflects remaining (unfixed) offenses

## Source Rule Design

### Overview

Source Rules operate on raw source strings rather than the AST. They are suited for rules that detect patterns in the text itself — such as trailing newlines, consecutive blank lines, or other file-level formatting concerns.

The TypeScript reference implementation (`@herb-tools/linter`) defines three rule types: `ParserRule`, `LexerRule`, and `SourceRule`. In the Ruby implementation, `VisitorRule` corresponds to `ParserRule`, and `SourceRule` is a new base class for source-level rules. `LexerRule` is not currently planned.

### SourceRule Base Class

```rbs
class Herb::Lint::Rules::SourceRule < Herb::Lint::Rules::Base
  # Delegates to check_source with the source string from context.
  # parse_result is accepted but ignored (interface compatibility with Linter#collect_offenses).
  def check: (Herb::ParseResult _parse_result, Herb::Lint::Context context) -> Array[Herb::Lint::Offense]

  # Subclasses implement this method.
  # Receives the raw source string and context for analysis.
  def check_source: (String source, Herb::Lint::Context context) -> void

  # Source-based autofix. Receives the offense (with recorded offsets) and current source.
  # Subclasses override to apply fixes. Returns corrected source or nil.
  # Must verify that content at recorded offsets still matches the expected pattern.
  def autofix_source: (Herb::Lint::Offense offense, String source) -> String?

  # Convenience method: add offense with source autofix context.
  # Creates AutofixContext with start_offset and end_offset (no node).
  def add_offense_with_source_autofix: (
    message: String,
    location: Herb::Location,
    start_offset: Integer,
    end_offset: Integer
  ) -> void

  private

  # Convert byte offsets to a Location object.
  def location_from_offsets: (Integer start_offset, Integer end_offset) -> Herb::Location

  # Convert a byte offset to line/column position (0-indexed).
  def position_from_offset: (Integer offset) -> { line: Integer, column: Integer }
end
```

**Key design decisions:**

1. **`check` accepts `parse_result` but ignores it.** This maintains a uniform interface with `VisitorRule` so `Linter#collect_offenses` does not need type dispatch. Both rule types are called with `rule.check(parse_result, context)`.

2. **`check_source` is the subclass entry point.** Receives the source string extracted from `context.source`. Subclasses use regex, string scanning, etc. to find violations.

3. **Position helpers are in the base class.** `location_from_offsets` and `position_from_offset` convert byte offsets to `Herb::Location` objects. These are needed by all source rules and are extracted from the current `NoExtraNewline` implementation.

### Source Rule Autofix: Offset Verification

Source Rule autofixes use byte offsets recorded at check time. When multiple fixes are applied sequentially to the same source string, earlier fixes may shift the byte positions of later offenses. Rather than recalculating offsets, the autofix method **verifies** that the content at the recorded offsets still matches the expected pattern:

```ruby
def autofix_source(offense, source)
  ctx = offense.autofix_context
  start_offset = ctx.start_offset
  end_offset = ctx.end_offset

  # Guard: verify content at recorded offsets
  actual_content = source[start_offset...end_offset]
  return nil unless valid_offense_content?(actual_content)

  # Apply fix
  apply_source_fix(source, start_offset, end_offset)
end
```

**Design rationale:**

- **No recalculation.** Recalculating offsets after each fix is complex and error-prone. Instead, if the content has shifted, the fix is skipped.
- **Explicit verification.** Each rule defines `valid_offense_content?` to check that the content at the recorded offsets is what the rule expects. For example, `NoExtraNewline` checks that the content is newlines only (`/\A\n+\z/`).
- **Idempotent safety.** If a fix was already applied (e.g., on a previous run), the verification will fail and the fix is safely skipped.
- **No reverse-order requirement.** The TypeScript reference sorts source offenses in reverse document order to minimize offset drift. With verification, reverse-order is not strictly required but can be used as an optimization.

### Source Rule Example: NoExtraNewline

```ruby
class NoExtraNewline < SourceRule
  def self.rule_name = "erb-no-extra-newline"
  def self.safe_autofixable? = true

  def check_source(source, _context)
    source.scan(/\n{4,}/) do
      match_data = Regexp.last_match
      match_start = match_data.begin(0)
      match_length = match_data[0].length

      offense_start = match_start + 3
      offense_end = match_start + match_length
      location = location_from_offsets(offense_start, offense_end)

      add_offense_with_source_autofix(
        message: "Extra blank line detected...",
        location:,
        start_offset: offense_start,
        end_offset: offense_end
      )
    end
  end

  def autofix_source(offense, source)
    ctx = offense.autofix_context
    content = source[ctx.start_offset...ctx.end_offset]

    # Verify: content at offsets should be newlines only
    return nil unless content&.match?(/\A\n+\z/)

    # Remove the extra newlines
    source[0...ctx.start_offset] + source[ctx.end_offset..]
  end
end
```

### AutoFixer: Two-Phase Processing

The `AutoFixer` separates offenses by type using `AutofixContext#source_rule?` and processes them in two phases:

```rbs
class Herb::Lint::AutoFixer
  def apply: () -> AutoFixResult

  private

  # Phase 1: AST fixes (VisitorRule offenses)
  # Mutates AST nodes via rule.autofix(node, parse_result)
  # Serializes via IdentityPrinter.print(parse_result) → source string
  def apply_ast_fixes: (Array[Offense] offenses) -> [String, Array[Offense], Array[Offense]]

  # Phase 2: Source fixes (SourceRule offenses)
  # Applies rule.autofix_source(offense, source) sequentially
  # Each fix operates on the result of the previous fix
  # Returns [final_source, fixed, unfixed]
  def apply_source_fixes: (Array[Offense] offenses, String source) -> [String, Array[Offense], Array[Offense]]
end
```

**Processing flow:**

```
AutoFixer#apply
  ├── partition fixable offenses by autofix_context.source_rule?
  │   ├── visitor_rule? offenses → ast_fixable
  │   └── source_rule? offenses → source_fixable
  │
  ├── Phase 1: apply_ast_fixes(ast_fixable)
  │   ├── for each offense: rule.autofix(node, parse_result) → bool
  │   └── IdentityPrinter.print(parse_result) → source
  │
  ├── Phase 2: apply_source_fixes(source_fixable, source)
  │   └── for each offense:
  │       ├── rule.autofix_source(offense, current_source)
  │       ├── verify content at offsets → skip if mismatch
  │       └── current_source = corrected_source
  │
  └── return AutoFixResult(source, fixed, unfixed)
```

### Testing Strategy for Source Rules

#### Unit Tests -- SourceRule Base Class

- `check` delegates to `check_source` with source string from context
- `check` ignores parse_result argument
- `autofix_source` default returns `nil`
- `add_offense_with_source_autofix` creates offense with `AutofixContext` containing offsets
- `location_from_offsets` correctly converts byte offsets to Location
- `position_from_offset` correctly handles newlines and multi-byte characters

#### Unit Tests -- AutofixContext (unified)

- `source_rule?` returns `true` when `start_offset` is present
- `source_rule?` returns `false` when `node` is present
- `visitor_rule?` returns `true` when `node` is present
- `visitor_rule?` returns `false` when `start_offset` is present
- `autofixable?` delegates to `rule_class.safe_autofixable?` and `unsafe_autofixable?`
- Backward compatibility: existing creation with `node:` still works

#### Unit Tests -- AutoFixer (source phase)

- Source offenses with valid offsets are fixed correctly
- Source offenses with shifted offsets (content mismatch) are skipped
- Mixed AST + source offenses: AST fixes applied first, then source fixes
- Multiple source offenses from the same rule applied sequentially
- `autofix_source` returning `nil` adds offense to unfixed list

#### Unit Tests -- NoExtraNewline (migrated to SourceRule)

- Detection logic unchanged (existing tests should still pass)
- Autofix removes extra newlines
- Autofix skips when content at offset has changed
- Autofix handles multiple occurrences in same file

## Related Documents

- [herb-lint Design](./herb-lint-design.md) -- Overall linter architecture
- [Printer Design](./printer-design.md) -- IdentityPrinter for AST-to-source serialization
- [Requirements: herb-lint](../requirements/herb-lint.md) -- CLI flags and fixable rule list
