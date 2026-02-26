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

- [x] Create CustomRewriterLoader class
- [x] Add initialize with config and registry
- [x] Implement load() method
- [x] Load rewriters from .herb/rewriters/*.rb
- [x] Auto-register loaded rewriter classes
- [x] Handle load errors gracefully
- [x] Add RBS inline type annotations
- [x] Create spec file

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

## Part C2: StringRewriter Support

### Task 4.13: Introduce ASTRewriter and StringRewriter Base Classes

**Background:**

The TypeScript reference implementation has two distinct base classes:

- `ASTRewriter` — operates on the parsed AST (`DocumentNode`), runs **before** formatting (pre phase)
- `StringRewriter` — operates on the formatted string, runs **after** formatting (post phase)

The current Ruby implementation has a single `Rewriters::Base` class that uses a `phase` attribute (`:pre` or `:post`) to indicate when it runs. This task replaces this with two dedicated classes matching the TypeScript design, improving type safety and clarity.

Note: The current `TailwindClassSorter` has `phase = :post` but operates on the AST. This task corrects it to inherit from `ASTRewriter` with `phase = :pre`, matching the TypeScript original.

**Locations:**
- `herb-format/lib/herb/format/rewriters/ast_rewriter.rb` (new)
- `herb-format/lib/herb/format/rewriters/string_rewriter.rb` (new)
- `herb-format/lib/herb/format/rewriters/base.rb` (updated — becomes internal common ancestor or removed)
- `herb-format/lib/herb/format/rewriters/tailwind_class_sorter.rb` (updated)
- `herb-format/lib/herb/format/rewriter_registry.rb` (updated)
- `herb-format/spec/herb/format/rewriters/ast_rewriter_spec.rb` (new)
- `herb-format/spec/herb/format/rewriters/string_rewriter_spec.rb` (new)

**Class Design:**

```ruby
module Herb
  module Format
    module Rewriters
      # Abstract base class for pre-format AST rewriters.
      # Operates on the parsed AST before FormatPrinter runs.
      class ASTRewriter
        def self.rewriter_name #: String
          raise NotImplementedError, "#{name} must implement self.rewriter_name"
        end

        def self.description #: String
          raise NotImplementedError, "#{name} must implement self.description"
        end

        def self.phase = :pre #: :pre

        # Optional setup hook, called once before first use.
        # @rbs context: { file_path: String?, base_dir: String }
        def setup(context) #: void
        end

        # @rbs ast: Herb::AST::DocumentNode
        # @rbs context: { file_path: String?, base_dir: String }
        def rewrite(ast, context) #: Herb::AST::DocumentNode
          raise NotImplementedError, "#{self.class.name} must implement #rewrite"
        end
      end

      # Abstract base class for post-format string rewriters.
      # Operates on the formatted string output from FormatPrinter.
      class StringRewriter
        def self.rewriter_name #: String
          raise NotImplementedError, "#{name} must implement self.rewriter_name"
        end

        def self.description #: String
          raise NotImplementedError, "#{name} must implement self.description"
        end

        def self.phase = :post #: :post

        # Optional setup hook, called once before first use.
        # @rbs context: { file_path: String?, base_dir: String }
        def setup(context) #: void
        end

        # @rbs formatted: String
        # @rbs context: { file_path: String?, base_dir: String }
        def rewrite(formatted, context) #: String
          raise NotImplementedError, "#{self.class.name} must implement #rewrite"
        end
      end
    end
  end
end
```

**Updated TailwindClassSorter:**

```ruby
class TailwindClassSorter < ASTRewriter
  def self.rewriter_name = "tailwind-class-sorter"
  def self.description = "Sort Tailwind CSS classes by recommended order"
  # phase = :pre inherited from ASTRewriter

  def rewrite(ast, context)
    # existing implementation
  end
end
```

**Updated RewriterRegistry validation:**

The registry must accept both `ASTRewriter` and `StringRewriter` subclasses:

```ruby
def validate_rewriter_class(rewriter_class)
  unless rewriter_class < Rewriters::ASTRewriter || rewriter_class < Rewriters::StringRewriter
    raise Errors::RewriterError, "Rewriter must inherit from Rewriters::ASTRewriter or Rewriters::StringRewriter"
  end
  rewriter_class.rewriter_name
  rewriter_class.description
  true
rescue NoMethodError, NotImplementedError => e
  raise Errors::RewriterError, "Rewriter class missing required method: #{e.message}"
end
```

**Phase validation (for Runner, Phase 5):**

When resolving rewriters from `rewriter.pre` and `rewriter.post` config lists:

```ruby
# pre list: must be ASTRewriter subclass
unless klass < Rewriters::ASTRewriter
  warn "Rewriter '#{name}' is not a pre-format rewriter. Skipping."
  next
end

# post list: must be StringRewriter subclass
unless klass < Rewriters::StringRewriter
  warn "Rewriter '#{name}' is not a post-format rewriter. Skipping."
  next
end
```

This mirrors TypeScript's `isASTRewriterClass` / `isStringRewriterClass` type guards.

**Checklist:**

- [ ] Create `herb-format/lib/herb/format/rewriters/ast_rewriter.rb`
- [ ] Create `herb-format/lib/herb/format/rewriters/string_rewriter.rb`
- [ ] Update `TailwindClassSorter` to inherit from `ASTRewriter` (and remove `phase` override — it inherits `:pre` from `ASTRewriter`)
- [ ] Update `RewriterRegistry#validate_rewriter_class` to accept both base classes
- [ ] Update `herb-format/lib/herb/format.rb` to require new files
- [ ] Remove or repurpose `Rewriters::Base` (keep as deprecated alias or remove if no specs depend on it)
- [ ] Update existing specs for `Rewriters::Base`, `TailwindClassSorter`, `RewriterRegistry`
- [ ] Add spec for `Rewriters::ASTRewriter`
- [ ] Add spec for `Rewriters::StringRewriter`
- [ ] Run rbs-inline to generate signatures
- [ ] Run steep check
- [ ] Run `cd herb-format && ./bin/rake` — all checks pass

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/rewriters/`

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
| 4.1 | A | Rewriter Base class | ✅ Done |
| 4.2 | A | RewriterRegistry | ✅ Done |
| 4.3 | B | TailwindClassSorter rewriter | ✅ Done |
| 4.4 | C | CustomRewriterLoader | ✅ Done |
| 4.5-4.7 | D | Integration and verification | Todo |
| 4.13 | C2 | ASTRewriter / StringRewriter base classes | Todo |

## Design Notes

### AST Modification API

The `herb` gem's AST may not support in-place modification. Options:

1. **Immutable AST with rebuilding** - Create new AST nodes with modifications
2. **Mutable AST** - Modify AST nodes in place (requires herb gem support)

**Recommendation:** Clarify AST mutation capabilities before implementing rewriter transformation logic.

## Related Documents

- [herb-format Design](../design/herb-format-design.md)
- [Phase 3: Formatter Core](./phase-3-formatter-core.md)
- [Phase 5: Runner](./phase-5-formatter-runner.md)
