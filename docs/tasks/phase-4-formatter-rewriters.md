# Phase 4: Formatter Rewriters

This phase implements the rewriter system for transforming ASTs before and after formatting.

**Design document:** [herb-format-design.md](../design/herb-format-design.md) (Rewriters section)

**Reference:** TypeScript `@herb-tools/rewriter` package built-in rewriters

## Overview

| Feature | Description | Status |
|---------|-------------|--------|
| Rewriter base class | Abstract interface for AST transformations | Done |
| RewriterRegistry | Central registry for rewriter classes | Done |
| TailwindClassSorter | Sort Tailwind CSS classes | Todo |
| CustomRewriterLoader | Load user-defined rewriters from .herb/rewriters/ | Todo |

## Prerequisites

- Phase 1 complete (Foundation)
- Phase 2 complete (FormatPrinter)
- Phase 3 complete (Formatter Core)
- herb gem available (Herb::Visitor for AST traversal)

## Design Principles

1. **Visitor-based transformation** - Rewriters use visitor pattern to traverse and modify AST
2. **Registry pattern** - Central registry for rewriter discovery
3. **Phase separation** - Pre-rewriters (before format) and post-rewriters (after format)
4. **Extensibility** - Users can add custom rewriters

---

## Part A: Rewriter Base and Registry (Done)

### Task 4.1: Create Rewriter Base Class ✅

**Location:** `herb-format/lib/herb/format/rewriters/base.rb`

### Task 4.2: Create RewriterRegistry ✅

**Location:** `herb-format/lib/herb/format/rewriter_registry.rb`

---

## Part B: Built-in Rewriters

### Task 4.3: Implement TailwindClassSorter Rewriter

**Location:** `herb-format/lib/herb/format/rewriters/tailwind_class_sorter.rb`

**Reference:** `@herb-tools/rewriter` built-in `tailwind-class-sorter`

- [x] Create TailwindClassSorter class extending Base
- [x] Implement rewriter_name returning "tailwind-class-sorter"
- [x] Implement description
- [x] Implement phase returning :post
- [x] Implement rewrite(ast, context) method
- [x] Sort Tailwind CSS classes according to recommended order
- [x] Add RBS inline type annotations
- [x] Create spec file
- [x] Register in load_builtin_rewriters

**Interface:**
```ruby
module Herb
  module Format
    module Rewriters
      # Sort Tailwind CSS classes according to recommended order.
      #
      # rbs_inline: enabled
      class TailwindClassSorter < Base
        # @rbs return: String
        def self.rewriter_name = "tailwind-class-sorter"

        # @rbs return: String
        def self.description = "Sort Tailwind CSS classes by recommended order"

        # @rbs return: Symbol
        def self.phase = :post

        # @rbs ast: Herb::AST::DocumentNode
        # @rbs context: Context
        # @rbs return: Herb::AST::DocumentNode
        def rewrite(ast, context)
          # traverse class attributes and sort Tailwind classes
          ast
        end
      end
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/rewriters/tailwind_class_sorter_spec.rb`

---

## Part C: Custom Rewriter Loader

### Task 4.4: Implement CustomRewriterLoader

**Location:** `herb-format/lib/herb/format/custom_rewriter_loader.rb`

**Reference:** `@herb-tools/rewriter` custom rewriter loading

- [ ] Create CustomRewriterLoader class
- [ ] Add initialize with config and registry
- [ ] Implement load() method
- [ ] Load rewriters from .herb/rewriters/*.rb
- [ ] Auto-register loaded rewriter classes
- [ ] Handle load errors gracefully
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
module Herb
  module Format
    # Loads custom rewriter implementations from configured paths.
    #
    # rbs_inline: enabled
    class CustomRewriterLoader
      DEFAULT_PATH = ".herb/rewriters"

      attr_reader :config, :registry

      # @rbs config: Herb::Config::FormatterConfig
      # @rbs registry: RewriterRegistry
      # @rbs return: void
      def initialize(config, registry)
        @config = config
        @registry = registry
      end

      # @rbs return: void
      def load
        load_rewriters_from(DEFAULT_PATH)
      end

      private

      # @rbs path: String
      # @rbs return: void
      def load_rewriters_from(path)
        return unless Dir.exist?(path)

        Dir.glob(File.join(path, "*.rb")).each do |file_path|
          require_rewriter_file(file_path)
        end

        auto_register_rewriters
      rescue StandardError => e
        warn "Failed to load custom rewriters from #{path}: #{e.message}"
      end

      # @rbs file_path: String
      # @rbs return: void
      def require_rewriter_file(file_path)
        require File.expand_path(file_path)
      rescue LoadError, StandardError => e
        warn "Failed to load rewriter file #{file_path}: #{e.message}"
      end

      # @rbs return: void
      def auto_register_rewriters
        Rewriters.constants.each do |const_name|
          const = Rewriters.const_get(const_name)
          next unless const.is_a?(Class) && const < Rewriters::Base
          next if registry.registered?(const.rewriter_name)

          registry.register(const)
        rescue StandardError => e
          warn "Failed to register rewriter #{const_name}: #{e.message}"
        end
      end
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/custom_rewriter_loader_spec.rb`

---

## Part D: Integration

### Task 4.5: Wire Up Rewriter Components

- [ ] Add `require_relative "format/rewriters/tailwind_class_sorter"` in format.rb
- [ ] Add `require_relative "format/custom_rewriter_loader"` in format.rb
- [ ] Register TailwindClassSorter in `load_builtin_rewriters`
- [ ] Run rbs-inline to generate signatures
- [ ] Run steep check

### Task 4.6: Update Runner to Use CustomRewriterLoader

**Note:** Implemented in Phase 5 when the Runner class is created.

- [ ] Runner calls `CustomRewriterLoader.new(config, registry).load` after `load_builtin_rewriters`

### Task 4.7: Full Verification

- [ ] Run `cd herb-format && ./bin/rake` -- all checks pass
- [ ] Verify TailwindClassSorter is registered as built-in
- [ ] Verify CustomRewriterLoader handles missing directory gracefully
- [ ] Verify custom rewriters in .herb/rewriters/ are auto-registered

---

## Summary

| Task | Part | Description | Status |
|------|------|-------------|--------|
| 4.1 | A | Rewriter Base class (herb-format) | ✅ Done (move to herb-rewriter, see 4.9) |
| 4.2 | A | RewriterRegistry (herb-format) | ✅ Done (move to herb-rewriter, see 4.11) |
| 4.3 | B | TailwindClassSorter rewriter (herb-format) | ✅ Done (move to herb-rewriter, see 4.9) |
| 4.4 | C | CustomRewriterLoader | → redesigned in separate task |
| 4.5-4.7 | D | Integration and verification | → superseded by 4.16-4.17 |
| 4.8 | E | Scaffold herb-rewriter gem | ✅ Done |
| 4.9 | E | Implement ASTRewriter + TailwindClassSorter in herb-rewriter | ✅ Done |
| 4.10 | E | Create StringRewriter in herb-rewriter | Todo |
| 4.11 | E | Move RewriterRegistry to herb-rewriter | Todo |
| 4.12 | E | Update herb-format to depend on herb-rewriter | Todo |
| 4.13 | E | Fix Formatter pipeline (Phase 3 design update) | Todo |
| 4.14 | E | Update FormatterFactory (Phase 3 design update) | Todo |
| 4.15 | E | StringRewriter integration — end-to-end verification | Todo |
| 4.16 | E | Update RBS signatures and file layout | Todo |
| 4.17 | E | Full verification | Todo |

## Design Notes

### AST Modification API

The `herb` gem's AST nodes are mutable objects in Ruby. The existing `TailwindClassSorter`
implementation uses `children.replace([new_literal])` which mutates in place successfully.
No special handling is required for AST mutation.

## Related Documents

- [herb-format Design](../design/herb-format-design.md)
- [Phase 3: Formatter Core](./phase-3-formatter-core.md)
- [Phase 5: Runner](./phase-5-formatter-runner.md)

---

## Part E: herb-rewriter Gem and Rewriter Design Revision

### Background and Problem Statement

Investigation of the original TypeScript implementation revealed that
`@herb-tools/rewriter` is a **separate npm package** that `@herb-tools/formatter` depends on.
The Ruby version should mirror this structure with a dedicated `herb-rewriter` gem.

**Package boundary (TypeScript → Ruby mapping):**

| TypeScript (`@herb-tools/rewriter`) | Ruby (`herb-rewriter` gem) |
|---|---|
| `ASTRewriter` abstract class | `Herb::Rewriter::ASTRewriter` |
| `StringRewriter` abstract class | `Herb::Rewriter::StringRewriter` |
| `RewriteContext` interface | `Herb::Rewriter::Context` |
| `CustomRewriterLoader` | `Herb::Rewriter::CustomRewriterLoader` |
| `TailwindClassSorterRewriter` (built-in) | `Herb::Rewriter::BuiltIns::TailwindClassSorter` |

**What stays in `herb-format`:**

| TypeScript (`@herb-tools/formatter`) | Ruby (`herb-format` gem) |
|---|---|
| `Formatter` class | `Herb::Format::Formatter` |
| `FormatPrinter` | `Herb::Format::FormatPrinter` |
| `FormatterFactory` / CLI | `Herb::Format::FormatterFactory`, `Herb::Format::CLI` |
| `FormatOptions` (pre/post rewriter arrays) | `Herb::Format::FormatterFactory` attributes |

**`RewriterRegistry`** — no direct TS equivalent. This Ruby-specific class manages registered
rewriter classes by type. It belongs in `herb-rewriter` as `Herb::Rewriter::Registry`.

**Two rewriter types:**

| Class | Phase | `rewrite()` input | `rewrite()` return |
|-------|-------|-------------------|--------------------|
| `ASTRewriter` | pre (before FormatPrinter) | `Herb::AST::DocumentNode` | `Herb::AST::DocumentNode` |
| `StringRewriter` | post (after FormatPrinter) | `String` | `String` |

**Processing pipeline:**

```
source (string)
  → parse()
  → node (AST)
  → [pre rewriters: apply ASTRewriter[] in order]     ← AST → AST
  → transformed node (AST)
  → FormatPrinter.print()                               ← AST/string boundary
  → formatted (string)
  → [post rewriters: apply StringRewriter[] in order]  ← string → string
  → output (string)
```

**Problems in the current Ruby implementation:**

1. `Rewriters::Base` is in `herb-format` — should be in a dedicated `herb-rewriter` gem
2. `Rewriters::Base` handles both pre and post with a single class, distinguished by a `phase` class method
3. The `rewrite(ast, context) -> ast` signature cannot support the post phase (`string → string`)
4. `TailwindClassSorter` is incorrectly set to `phase = :post` but is actually an `ASTRewriter`
5. The Phase 3 `Formatter` design passes AST to post-rewriters, which is incorrect

---

### Task 4.8: Scaffold `herb-rewriter` gem

Create the gem skeleton following the same conventions as `herb-printer`.

**Directory layout:**

```
herb-rewriter/
├── Gemfile                          # gemspec + dev deps (same as herb-printer)
├── Gemfile.lock
├── Rakefile                         # spec, rubocop, steep tasks
├── Steepfile
├── bin/                             # binstubs: rake, rbs, rbs-inline, rspec, rubocop, steep
├── herb-rewriter.gemspec
├── lib/
│   ├── herb/
│   │   ├── rewriter/
│   │   │   ├── version.rb
│   │   │   ├── context.rb
│   │   │   ├── ast_rewriter.rb
│   │   │   ├── string_rewriter.rb
│   │   │   ├── registry.rb
│   │   │   └── built_ins/
│   │   │       ├── index.rb
│   │   │       └── tailwind_class_sorter.rb
│   │   └── rewriter.rb              # requires all of the above
├── rbs_collection.yaml
├── sig/
└── spec/
    ├── spec_helper.rb
    └── herb/
        └── rewriter/
            ├── context_spec.rb
            ├── ast_rewriter_spec.rb
            ├── string_rewriter_spec.rb
            ├── registry_spec.rb
            └── built_ins/
                └── tailwind_class_sorter_spec.rb
```

**Checklist:**

- [x] Create directory structure above
- [x] `herb-rewriter.gemspec`: `spec.name = "herb-rewriter"`, `spec.add_dependency "herb"`
- [x] `Gemfile`: `gemspec` + same dev deps as `herb-printer`
- [x] `Rakefile`: copy from `herb-printer` (spec, rubocop, steep tasks)
- [x] `Steepfile`: copy from `herb-printer`
- [x] `bin/`: copy binstubs from `herb-printer/bin/`; update `Gemfile` path references
- [x] `lib/herb/rewriter/version.rb`: `Herb::Rewriter::VERSION = "0.1.0"`
- [x] `lib/herb/rewriter.rb`: `require` all sub-files
- [x] `spec/spec_helper.rb`: copy from `herb-printer`
- [x] `rbs_collection.yaml`: copy from `herb-printer`
- [x] Run `cd herb-rewriter && ./bin/bundle install`

**Verification:**
- `cd herb-rewriter && ./bin/rspec` — runs (zero examples, no failures)
- `cd herb-rewriter && ./bin/rubocop` — passes

---

### Task 4.9: Implement `ASTRewriter` and move `TailwindClassSorter` to `herb-rewriter`

**Locations:**
- `herb-rewriter/lib/herb/rewriter/ast_rewriter.rb` (new — based on current `herb-format/lib/herb/format/rewriters/base.rb`)
- `herb-rewriter/lib/herb/rewriter/built_ins/tailwind_class_sorter.rb` (moved from herb-format)
- `herb-format/lib/herb/format/rewriters/base.rb` → delete after move

`Rewriters::Base` in herb-format already has the correct interface for an AST rewriter.
Port it to `herb-rewriter` with the renamed class and namespace, then remove it from herb-format.

- [x] Create `herb-rewriter/lib/herb/rewriter/ast_rewriter.rb`; class `Herb::Rewriter::ASTRewriter`
- [x] Remove `def self.phase` (being an ASTRewriter implies pre phase)
- [x] Move `herb-format/.../tailwind_class_sorter.rb` to `herb-rewriter/.../built_ins/tailwind_class_sorter.rb`
- [x] Update `TailwindClassSorter`: namespace `Herb::Rewriter::BuiltIns`, inherit `< Herb::Rewriter::ASTRewriter`, remove `def self.phase = :post`
- [x] Create `herb-rewriter/.../built_ins/index.rb` to require the built-in
- [x] Move specs to `herb-rewriter/spec/herb/rewriter/`
- [x] Delete `herb-format/lib/herb/format/rewriters/base.rb` and its spec

**Verification:**
- `cd herb-rewriter && ./bin/rspec spec/herb/rewriter/`

---

### Task 4.10: Create `StringRewriter` in `herb-rewriter`

**Location:** `herb-rewriter/lib/herb/rewriter/string_rewriter.rb`

- [x] Create `string_rewriter.rb`; class `Herb::Rewriter::StringRewriter`
- [x] Define `rewrite(formatted, context) -> String` as an abstract method
- [x] Add RBS inline type annotations
- [x] Create spec file

**Interface:**

```ruby
module Herb
  module Rewriter
    # Abstract base class for string-based post-format rewriters.
    #
    # Receives the formatted string output from FormatPrinter and returns
    # a transformed string. Applied in the post phase of the formatting pipeline.
    #
    # Example use cases: ensuring trailing newline, normalizing line endings.
    #
    # rbs_inline: enabled
    class StringRewriter
      def self.rewriter_name #: String
        raise NotImplementedError, "#{name} must implement self.rewriter_name"
      end

      def self.description #: String
        raise NotImplementedError, "#{name} must implement self.description"
      end

      # Transform formatted string and return modified string.
      #
      # @rbs formatted: String
      # @rbs context: Herb::Rewriter::Context
      def rewrite(formatted, context) #: String
        raise NotImplementedError, "#{self.class.name} must implement #rewrite"
      end
    end
  end
end
```

**Verification:**
- `cd herb-rewriter && ./bin/rspec spec/herb/rewriter/string_rewriter_spec.rb`

---

### Task 4.11: Move `RewriterRegistry` to `herb-rewriter`

**Location:** `herb-rewriter/lib/herb/rewriter/registry.rb`
(replaces `herb-format/lib/herb/format/rewriter_registry.rb`)

**Design note:** Built-in rewriters are **opt-in only** — the TypeScript implementation
never auto-applies any rewriter. Built-ins are a static catalog used for name resolution
when the user lists rewriter names in `.herb.yml`. There is no `load_builtin_rewriters`
pre-registration step.

- [ ] Create `Herb::Rewriter::Registry` class
- [ ] Define `BUILTIN_AST_REWRITERS` constant listing built-in AST rewriter classes
- [ ] Define `BUILTIN_STRING_REWRITERS` constant listing built-in String rewriter classes
- [ ] Internal storage for custom rewriters: `@custom_ast_rewriters`, `@custom_string_rewriters`
- [ ] `register(klass)` dispatches via `klass < ASTRewriter` or `klass < StringRewriter`
- [ ] `get_ast_rewriter(name)` checks custom first, then `BUILTIN_AST_REWRITERS`
- [ ] `get_string_rewriter(name)` checks custom first, then `BUILTIN_STRING_REWRITERS`
- [ ] `registered?(name)` delegates to `get_ast_rewriter` / `get_string_rewriter`
- [ ] Create spec at `herb-rewriter/spec/herb/rewriter/registry_spec.rb`
- [ ] Delete `herb-format/lib/herb/format/rewriter_registry.rb` and its spec

**Interface:**

```ruby
module Herb
  module Rewriter
    class Registry
      BUILTIN_AST_REWRITERS = [BuiltIns::TailwindClassSorter].freeze #: Array[singleton(ASTRewriter)]
      BUILTIN_STRING_REWRITERS = [].freeze                           #: Array[singleton(StringRewriter)]

      def initialize #: void
        @custom_ast_rewriters = {}    #: Hash[String, singleton(ASTRewriter)]
        @custom_string_rewriters = {} #: Hash[String, singleton(StringRewriter)]
      end

      # Register a custom rewriter class.
      # @rbs klass: singleton(ASTRewriter) | singleton(StringRewriter)
      def register(klass) #: void
        if klass < ASTRewriter
          @custom_ast_rewriters[klass.rewriter_name] = klass
        elsif klass < StringRewriter
          @custom_string_rewriters[klass.rewriter_name] = klass
        else
          raise ArgumentError, "Rewriter must inherit from ASTRewriter or StringRewriter"
        end
      end

      # Resolve a name to an AST rewriter class.
      # Custom rewriters shadow built-ins of the same name.
      #
      # @rbs name: String
      def get_ast_rewriter(name) #: singleton(ASTRewriter)?
        @custom_ast_rewriters[name] ||
          BUILTIN_AST_REWRITERS.find { _1.rewriter_name == name }
      end

      # Resolve a name to a String rewriter class.
      # Custom rewriters shadow built-ins of the same name.
      #
      # @rbs name: String
      def get_string_rewriter(name) #: singleton(StringRewriter)?
        @custom_string_rewriters[name] ||
          BUILTIN_STRING_REWRITERS.find { _1.rewriter_name == name }
      end

      def registered?(name) #: bool
        !get_ast_rewriter(name).nil? || !get_string_rewriter(name).nil?
      end
    end
  end
end
```

**Verification:**
- `cd herb-rewriter && ./bin/rspec spec/herb/rewriter/registry_spec.rb`

---

### Task 4.12: Update `herb-format` to depend on `herb-rewriter`

**Location:** `herb-format/herb-format.gemspec`, `herb-format/Gemfile`, `herb-format/lib/herb/format.rb`

Note: `require_relative "format/rewriters/base"` and `require_relative "format/rewriters/tailwind_class_sorter"`
were already removed from `format.rb` in Task 4.9.

- [ ] Add `spec.add_dependency "herb-rewriter"` to `herb-format.gemspec`
- [ ] Add `gem "herb-rewriter", path: "../herb-rewriter"` to `herb-format/Gemfile` (local path for development)
- [ ] Replace `require_relative "format/rewriter_registry"` with `require "herb/rewriter"` in `herb-format/lib/herb/format.rb`
- [ ] Run `cd herb-format && ./bin/bundle install`

**Verification:**
- `cd herb-format && ./bin/rspec` — all existing specs still pass

---

### Task 4.13: Fix `Formatter` pipeline (Phase 3 design update)

**Location:** `herb-format/lib/herb/format/formatter.rb` (not yet implemented)

Update the Phase 3 Formatter design so that post-rewriters receive and return a string,
using types from `herb-rewriter`.

- [ ] Declare `pre_rewriters` as `Array[Herb::Rewriter::ASTRewriter]`
- [ ] Declare `post_rewriters` as `Array[Herb::Rewriter::StringRewriter]`
- [ ] Implement `apply_pre_rewriters(ast, rewriters, context) -> Herb::AST::DocumentNode`
- [ ] Implement `apply_post_rewriters(formatted, rewriters, context) -> String`
- [ ] Apply post-rewriters **after** `FormatPrinter.format()` in the `format()` method
- [ ] Update RBS type annotations
- [ ] Update Phase 3 spec

**Corrected format() pipeline:**

```ruby
def format(file_path, source, force: false)
  parse_result = Herb.parse(source)
  # ... parse error handling, ignore check ...
  context = Context.new(file_path: file_path, source: source, config: config)

  # 1. pre-rewriters: AST → AST
  ast = apply_pre_rewriters(ast, pre_rewriters, context)

  # 2. FormatPrinter: AST → string  (AST/string boundary)
  formatted = FormatPrinter.format(ast, format_context: context)

  # 3. post-rewriters: string → string
  formatted = apply_post_rewriters(formatted, post_rewriters, context)

  FormatResult.new(file_path: file_path, original: source, formatted: formatted)
end

private

# @rbs ast: Herb::AST::DocumentNode
# @rbs rewriters: Array[Herb::Rewriter::ASTRewriter]
# @rbs context: Context
def apply_pre_rewriters(ast, rewriters, context) #: Herb::AST::DocumentNode
  rewriters.reduce(ast) { |node, rw| rw.rewrite(node, context) }
end

# @rbs formatted: String
# @rbs rewriters: Array[Herb::Rewriter::StringRewriter]
# @rbs context: Context
def apply_post_rewriters(formatted, rewriters, context) #: String
  rewriters.reduce(formatted) { |str, rw| rw.rewrite(str, context) }
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/formatter_spec.rb`

---

### Task 4.14: Update `FormatterFactory` (Phase 3 design update)

**Location:** `herb-format/lib/herb/format/formatter_factory.rb` (not yet implemented)

Update `FormatterFactory` to use the `Herb::Rewriter::Registry` API.

- [ ] Change return type of `build_pre_rewriters` to `Array[Herb::Rewriter::ASTRewriter]`
- [ ] Change return type of `build_post_rewriters` to `Array[Herb::Rewriter::StringRewriter]`
- [ ] Use `rewriter_registry.get_ast_rewriter(name)` / `get_string_rewriter(name)`
- [ ] Update RBS type annotations

**Updated methods:**

```ruby
# @rbs return: Array[Herb::Rewriter::ASTRewriter]
def build_pre_rewriters
  config.rewriter_pre.filter_map do |name|
    klass = rewriter_registry.get_ast_rewriter(name)
    warn "Unknown pre-rewriter '#{name}'" unless klass
    klass&.new
  end
end

# @rbs return: Array[Herb::Rewriter::StringRewriter]
def build_post_rewriters
  config.rewriter_post.filter_map do |name|
    klass = rewriter_registry.get_string_rewriter(name)
    warn "Unknown post-rewriter '#{name}'" unless klass
    klass&.new
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/formatter_factory_spec.rb`

---

### Task 4.15: StringRewriter integration — end-to-end verification

The `StringRewriter` base class is created in Task 4.10. This task verifies it is correctly
integrated into every layer of the formatting pipeline.

**Checklist:**

- [ ] Create a minimal `IdentityStringRewriter` stub (returns source unchanged) in `spec/support/`
  and confirm it can be registered with `Herb::Rewriter::Registry`
- [ ] Write an integration spec that runs the full `Formatter` pipeline with the stub registered
  as a post-rewriter and asserts the output matches expectations
- [ ] Confirm `Herb::Rewriter::Registry#get_string_rewriter` returns the stub by name
- [ ] Confirm `FormatterFactory#build_post_rewriters` instantiates it correctly
- [ ] Remove `# TODO: StringRewriter support` comments added in 4.10–4.14

**Note:** Auto-registration via `CustomRewriterLoader` is handled in the separate redesign task.
This task only covers the registry/pipeline integration path.

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/integration/`

---

### Task 4.16: Update RBS signatures and file layout

**herb-rewriter:**
- [ ] Run `cd herb-rewriter && ./bin/rbs-inline` to generate `sig/`
- [ ] Confirm `cd herb-rewriter && ./bin/steep check` passes with no errors

**herb-format:**
- [ ] Confirm `require "herb/rewriter"` is the sole require for rewriter base classes
- [ ] Remove any lingering `require_relative "format/rewriters/..."` for moved files
- [ ] Run `cd herb-format && ./bin/rbs-inline` to regenerate signatures
- [ ] Confirm `cd herb-format && ./bin/steep check` passes with no errors

---

### Task 4.17: Full verification

- [ ] `cd herb-rewriter && ./bin/rake` — spec, rubocop, and steep all pass
- [ ] `cd herb-format && ./bin/rake` — spec, rubocop, and steep all pass
- [ ] Unit tests for `ASTRewriter` and `StringRewriter` pass in `herb-rewriter`
- [ ] `Registry.new.get_ast_rewriter("tailwind-class-sorter")` returns `BuiltIns::TailwindClassSorter`
- [ ] Integration test confirms post-rewriters receive a string in the `Formatter` pipeline
- [ ] `herb-format` has no direct references to removed classes (`Rewriters::Base`, etc.)
