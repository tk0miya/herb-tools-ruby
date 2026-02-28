# herb-rewriter Design Document

Architectural design for the rewriter base classes and registry gem.

## Overview

herb-rewriter provides abstract base classes and a central registry for rewriter implementations. It is a standalone gem that mirrors the TypeScript `@herb-tools/rewriter` package. The gem is consumed by `herb-format` and can also be used directly by users who want to write custom rewriters.

## Directory Structure

```
herb-rewriter/
├── lib/
│   └── herb/
│       └── rewriter/
│           ├── version.rb
│           ├── ast_rewriter.rb
│           ├── string_rewriter.rb
│           ├── registry.rb
│           ├── context.rb
│           └── built_ins/
│               ├── index.rb
│               └── tailwind_class_sorter.rb
├── spec/
│   └── herb/
│       └── rewriter/
│           ├── ast_rewriter_spec.rb
│           ├── string_rewriter_spec.rb
│           ├── registry_spec.rb
│           ├── context_spec.rb
│           └── built_ins/
│               └── tailwind_class_sorter_spec.rb
├── herb-rewriter.gemspec
└── Gemfile
```

## Class Design

### Module Structure

```
Herb::Rewriter
├── ASTRewriter      # Abstract base for pre-format AST-to-AST rewriters
├── StringRewriter   # Abstract base for post-format string-to-string rewriters
├── Registry         # Rewriter registration and lookup (Registry Pattern)
├── Context          # Rewrite execution context
└── BuiltIns
    └── TailwindClassSorter  # Sort Tailwind CSS classes
```

## Two-Phase Rewriter Model

Rewriters operate in two distinct phases of the formatting pipeline:

```
source (string)
  → Herb.parse()
  → ast (DocumentNode)
  → [pre phase: ASTRewriter[] applied in order]   ← AST → AST
  → transformed ast (DocumentNode)
  → FormatPrinter.format()                          ← AST/string boundary
  → formatted (string)
  → [post phase: StringRewriter[] applied in order] ← String → String
  → output (string)
```

| Phase | Base Class | Input | Output | Example |
|-------|-----------|-------|--------|---------|
| pre   | `ASTRewriter` | `Herb::AST::DocumentNode` | `Herb::AST::DocumentNode` | TailwindClassSorter |
| post  | `StringRewriter` | `String` | `String` | trailing newline normalizer |

## Component Details

### Herb::Rewriter::ASTRewriter

**Responsibility:** Abstract base class for pre-format rewriters (AST → AST transformation).

```rbs
class Herb::Rewriter::ASTRewriter
  attr_reader options: Hash[Symbol, untyped]

  def self.rewriter_name: () -> String
  def self.description: () -> String

  def initialize: (?options: Hash[Symbol, untyped]) -> void
  def rewrite: (Herb::AST::DocumentNode ast, Herb::Rewriter::Context context) -> Herb::AST::DocumentNode

  private

  def traverse: (Herb::AST::Node node) { (Herb::AST::Node) -> Herb::AST::Node? } -> Herb::AST::Node
end
```

**Design Decisions:**
- No `phase` class method — being an `ASTRewriter` implies the pre phase
- Subclasses override `rewrite` to transform the AST in place or return a new root
- `traverse` helper simplifies recursive AST traversal

### Herb::Rewriter::StringRewriter

**Responsibility:** Abstract base class for post-format rewriters (String → String transformation).

```rbs
class Herb::Rewriter::StringRewriter
  def self.rewriter_name: () -> String
  def self.description: () -> String

  def rewrite: (String formatted, Herb::Rewriter::Context context) -> String
end
```

**Design Decisions:**
- No `phase` class method — being a `StringRewriter` implies the post phase
- Subclasses override `rewrite` to transform the formatted string and return the result

### Herb::Rewriter::Registry

**Responsibility:** Central registry for rewriter classes (Registry Pattern).

```rbs
class Herb::Rewriter::Registry
  BUILTIN_AST_REWRITERS: Array[singleton(ASTRewriter)]
  BUILTIN_STRING_REWRITERS: Array[singleton(StringRewriter)]

  def initialize: () -> void

  def register: (singleton(ASTRewriter) | singleton(StringRewriter) klass) -> void
  def registered?: (String name) -> bool
  def get_ast_rewriter: (String name) -> singleton(ASTRewriter)?
  def get_string_rewriter: (String name) -> singleton(StringRewriter)?
end
```

**Built-in Rewriters:**

| Name | Type | Description |
|------|------|-------------|
| `tailwind-class-sorter` | ASTRewriter (pre) | Sort Tailwind CSS classes by recommended order |

**Design Decisions:**
- Built-in rewriters are **opt-in only** — they are never auto-applied. The `BUILTIN_*` constants serve as a static catalog for name resolution when the user lists rewriter names in `.herb.yml`.
- Custom rewriters registered via `register(klass)` shadow built-ins of the same name.
- Custom rewriters take precedence: `get_ast_rewriter(name)` checks `@custom_ast_rewriters` before `BUILTIN_AST_REWRITERS`.

### Herb::Rewriter::Context

**Responsibility:** Provides contextual information available to rewriters during execution.

```rbs
class Herb::Rewriter::Context
  attr_reader file_path: String
  attr_reader source: String
  attr_reader config: Herb::Config::FormatterConfig

  def initialize: (
    file_path: String,
    source: String,
    config: Herb::Config::FormatterConfig
  ) -> void
end
```

### Herb::Rewriter::BuiltIns::TailwindClassSorter

**Purpose:** Sort Tailwind CSS classes according to recommended order.

```rbs
class Herb::Rewriter::BuiltIns::TailwindClassSorter < Herb::Rewriter::ASTRewriter
  def self.rewriter_name: () -> String  # "tailwind-class-sorter"
  def self.description: () -> String

  def rewrite: (Herb::AST::DocumentNode ast, Herb::Rewriter::Context context) -> Herb::AST::DocumentNode

  private

  def sort_class_attribute: (Herb::AST::HTMLAttributeNode attr) -> void
  def tailwind_sort_key: (String class_name) -> Integer
end
```

**Responsibilities:**
- Traverse the AST to find `class` attributes on HTML elements
- Sort class values according to the Tailwind CSS recommended order
- Run in the pre phase (before FormatPrinter) as an `ASTRewriter`

## TypeScript Parity

| TypeScript (`@herb-tools/rewriter`) | Ruby (`herb-rewriter` gem) |
|---|---|
| `ASTRewriter` abstract class | `Herb::Rewriter::ASTRewriter` |
| `StringRewriter` abstract class | `Herb::Rewriter::StringRewriter` |
| `RewriteContext` interface | `Herb::Rewriter::Context` |
| `TailwindClassSorterRewriter` (built-in) | `Herb::Rewriter::BuiltIns::TailwindClassSorter` |

**Ruby-specific addition:** `Herb::Rewriter::Registry` has no direct TypeScript equivalent. It manages registered rewriter classes by type and provides name-based lookup used by `FormatterFactory`.

## Related Documents

- [Overall Architecture](./architecture.md)
- [herb-format Design](./herb-format-design.md) — shows how herb-rewriter integrates into the formatting pipeline
- [Requirements: herb-format](../requirements/herb-format.md)
