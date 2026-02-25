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

- [ ] Create TailwindClassSorter class extending Base
- [ ] Implement rewriter_name returning "tailwind-class-sorter"
- [ ] Implement description
- [ ] Implement phase returning :post
- [ ] Implement rewrite(ast, context) method
- [ ] Sort Tailwind CSS classes according to recommended order
- [ ] Add RBS inline type annotations
- [ ] Create spec file
- [ ] Register in load_builtin_rewriters

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
| 4.1 | A | Rewriter Base class | ✅ Done |
| 4.2 | A | RewriterRegistry | ✅ Done |
| 4.3 | B | TailwindClassSorter rewriter | Todo |
| 4.4 | C | CustomRewriterLoader | Todo |
| 4.5-4.7 | D | Integration and verification | Todo |

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
