# Phase 4: Formatter Rewriters

This phase implements the rewriter system for transforming ASTs before and after formatting.

**Design document:** [herb-format-design.md](../design/herb-format-design.md) (Rewriters section)

**Reference:** TypeScript `@herb-tools/formatter` Rewriter implementations

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| Rewriter base class | Abstract interface for AST transformations | Foundation for all rewriters |
| RewriterRegistry | Central registry for rewriter classes | Enables rewriter discovery and loading |
| Built-in rewriters | NormalizeAttributes, SortAttributes, TailwindClassSorter | Common formatting transformations |
| Custom rewriter loader | Load user-defined rewriters from .herb/rewriters/ | Extensibility |

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

## Part A: Rewriter Base and Registry

### Task 4.1: Create Rewriter Base Class

**Location:** `herb-format/lib/herb/format/rewriters/base.rb`

- [ ] Create Rewriters module
- [ ] Create Base class extending or using Herb::Visitor
- [ ] Define class methods: rewriter_name, description, phase
- [ ] Define instance method: rewrite(ast, context)
- [ ] Add helper method: traverse(node, &block) for AST modification
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    module Rewriters
      # Abstract base class defining the rewriter interface.
      #
      # All rewriters must implement:
      # - self.rewriter_name: () -> String (kebab-case identifier)
      # - self.description: () -> String (human-readable description)
      # - self.phase: () -> Symbol (:pre or :post)
      # - rewrite: (Herb::AST::DocumentNode, Context) -> Herb::AST::DocumentNode
      #
      # @rbs!
      #   class Base
      #     attr_reader options: Hash[Symbol, untyped]
      #
      #     def self.rewriter_name: () -> String
      #     def self.description: () -> String
      #     def self.phase: () -> Symbol
      #
      #     def initialize: (?options: Hash[Symbol, untyped]) -> void
      #     def rewrite: (Herb::AST::DocumentNode ast, Context context) -> Herb::AST::DocumentNode
      #
      #     private
      #     def traverse: (Herb::AST::Node node) { (Herb::AST::Node) -> Herb::AST::Node? } -> Herb::AST::Node
      #   end
      class Base
        attr_reader :options

        # @rbs return: String
        def self.rewriter_name
          raise NotImplementedError, "#{name} must implement self.rewriter_name"
        end

        # @rbs return: String
        def self.description
          raise NotImplementedError, "#{name} must implement self.description"
        end

        # @rbs return: Symbol
        def self.phase
          :post # Default to post-formatting phase
        end

        # @rbs options: Hash[Symbol, untyped]
        # @rbs return: void
        def initialize(options: {})
          @options = options
        end

        # Transform AST and return modified AST.
        #
        # @rbs ast: Herb::AST::DocumentNode
        # @rbs context: Context
        # @rbs return: Herb::AST::DocumentNode
        def rewrite(ast, context)
          raise NotImplementedError, "#{self.class.name} must implement #rewrite"
        end

        private

        # Traverse AST and apply transformations via block.
        # The block receives each node and can return a replacement node or nil.
        #
        # @rbs node: Herb::AST::Node
        # @rbs block: Proc
        # @rbs return: Herb::AST::Node
        def traverse(node, &block)
          # Apply block transformation to current node
          transformed = block.call(node)
          node = transformed if transformed

          # Recursively traverse children
          if node.respond_to?(:child_nodes)
            node.child_nodes.each do |child|
              traverse(child, &block)
            end
          end

          node
        end
      end
    end
  end
end
```

**Test Cases:**
```ruby
RSpec.describe Herb::Format::Rewriters::Base do
  describe "class methods" do
    it "raises NotImplementedError for rewriter_name" do
      expect { described_class.rewriter_name }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for description" do
      expect { described_class.description }.to raise_error(NotImplementedError)
    end

    it "returns :post for default phase" do
      expect(described_class.phase).to eq(:post)
    end
  end

  describe "#rewrite" do
    it "raises NotImplementedError" do
      rewriter = described_class.new
      ast = instance_double(Herb::AST::DocumentNode)
      context = instance_double(Herb::Format::Context)

      expect { rewriter.rewrite(ast, context) }.to raise_error(NotImplementedError)
    end
  end

  describe "#initialize" do
    it "accepts options" do
      rewriter = described_class.new(options: { foo: "bar" })
      expect(rewriter.options).to eq({ foo: "bar" })
    end

    it "defaults options to empty hash" do
      rewriter = described_class.new
      expect(rewriter.options).to eq({})
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/rewriters/base_spec.rb`

---

### Task 4.2: Create RewriterRegistry

**Location:** `herb-format/lib/herb/format/rewriter_registry.rb`

- [ ] Create RewriterRegistry class
- [ ] Implement register(rewriter_class) method
- [ ] Implement get(name) method returning rewriter class or nil
- [ ] Implement registered?(name) predicate
- [ ] Implement all() method returning all registered rewriters
- [ ] Implement rewriter_names() method
- [ ] Implement load_builtin_rewriters() method
- [ ] Add validation for rewriter classes
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Central registry for rewriter classes (Registry Pattern).
    #
    # @rbs @rewriters: Hash[String, singleton(Rewriters::Base)]
    class RewriterRegistry
      # @rbs return: void
      def initialize
        @rewriters = {}
      end

      # Register a rewriter class.
      #
      # @rbs rewriter_class: singleton(Rewriters::Base)
      # @rbs return: void
      def register(rewriter_class)
        validate_rewriter_class(rewriter_class)
        name = rewriter_class.rewriter_name
        @rewriters[name] = rewriter_class
      end

      # Get a rewriter class by name.
      #
      # @rbs name: String
      # @rbs return: singleton(Rewriters::Base)?
      def get(name)
        @rewriters[name]
      end

      # Check if a rewriter is registered.
      #
      # @rbs name: String
      # @rbs return: bool
      def registered?(name)
        @rewriters.key?(name)
      end

      # Get all registered rewriter classes.
      #
      # @rbs return: Array[singleton(Rewriters::Base)]
      def all
        @rewriters.values
      end

      # Get all registered rewriter names.
      #
      # @rbs return: Array[String]
      def rewriter_names
        @rewriters.keys
      end

      # Load built-in rewriters.
      #
      # @rbs return: void
      def load_builtin_rewriters
        require_relative "rewriters/normalize_attributes"
        require_relative "rewriters/sort_attributes"
        require_relative "rewriters/tailwind_class_sorter"

        register(Rewriters::NormalizeAttributes)
        register(Rewriters::SortAttributes)
        register(Rewriters::TailwindClassSorter)
      end

      private

      # @rbs rewriter_class: singleton(Rewriters::Base)
      # @rbs return: bool
      def validate_rewriter_class(rewriter_class)
        unless rewriter_class < Rewriters::Base
          raise Errors::RewriterError, "Rewriter must inherit from Rewriters::Base"
        end

        # Ensure required class methods are implemented
        rewriter_class.rewriter_name
        rewriter_class.description
        rewriter_class.phase

        true
      rescue NoMethodError => e
        raise Errors::RewriterError, "Rewriter class missing required method: #{e.message}"
      end
    end
  end
end
```

**Test Cases:**
```ruby
RSpec.describe Herb::Format::RewriterRegistry do
  let(:registry) { described_class.new }

  let(:test_rewriter_class) do
    Class.new(Herb::Format::Rewriters::Base) do
      def self.rewriter_name = "test-rewriter"
      def self.description = "Test rewriter"
      def self.phase = :post
      def rewrite(ast, _context) = ast
    end
  end

  describe "#register" do
    it "registers a rewriter class" do
      registry.register(test_rewriter_class)
      expect(registry.registered?("test-rewriter")).to be true
    end

    it "raises error for non-Base subclass" do
      invalid_class = Class.new

      expect {
        registry.register(invalid_class)
      }.to raise_error(Herb::Format::Errors::RewriterError, /must inherit/)
    end

    it "raises error for class missing rewriter_name" do
      invalid_class = Class.new(Herb::Format::Rewriters::Base)

      expect {
        registry.register(invalid_class)
      }.to raise_error(Herb::Format::Errors::RewriterError, /missing required method/)
    end
  end

  describe "#get" do
    it "returns registered rewriter class" do
      registry.register(test_rewriter_class)
      expect(registry.get("test-rewriter")).to eq(test_rewriter_class)
    end

    it "returns nil for unregistered name" do
      expect(registry.get("unknown")).to be_nil
    end
  end

  describe "#registered?" do
    it "returns true for registered rewriter" do
      registry.register(test_rewriter_class)
      expect(registry.registered?("test-rewriter")).to be true
    end

    it "returns false for unregistered rewriter" do
      expect(registry.registered?("unknown")).to be false
    end
  end

  describe "#all" do
    it "returns all registered rewriter classes" do
      registry.register(test_rewriter_class)
      expect(registry.all).to eq([test_rewriter_class])
    end
  end

  describe "#rewriter_names" do
    it "returns all registered rewriter names" do
      registry.register(test_rewriter_class)
      expect(registry.rewriter_names).to eq(["test-rewriter"])
    end
  end

  describe "#load_builtin_rewriters" do
    it "loads and registers built-in rewriters" do
      registry.load_builtin_rewriters

      expect(registry.registered?("normalize-attributes")).to be true
      expect(registry.registered?("sort-attributes")).to be true
      expect(registry.registered?("tailwind-class-sorter")).to be true
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/rewriter_registry_spec.rb`

---

## Part B: Built-in Rewriters

### Task 4.3: Implement NormalizeAttributes Rewriter

**Location:** `herb-format/lib/herb/format/rewriters/normalize_attributes.rb`

- [ ] Create NormalizeAttributes class extending Base
- [ ] Implement rewriter_name returning "normalize-attributes"
- [ ] Implement description
- [ ] Implement phase returning :pre
- [ ] Implement rewrite(ast, context) method
- [ ] Convert single quotes to double quotes in attribute values
- [ ] Normalize whitespace in attribute values
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    module Rewriters
      # Normalize attribute formatting before main formatting pass.
      #
      # Transformations:
      # - Convert single quotes to double quotes
      # - Normalize whitespace in attribute values
      class NormalizeAttributes < Base
        # @rbs return: String
        def self.rewriter_name = "normalize-attributes"

        # @rbs return: String
        def self.description = "Normalize attribute formatting (quotes, whitespace)"

        # @rbs return: Symbol
        def self.phase = :pre

        # @rbs ast: Herb::AST::DocumentNode
        # @rbs context: Context
        # @rbs return: Herb::AST::DocumentNode
        def rewrite(ast, context)
          traverse(ast) do |node|
            normalize_attribute(node) if node.type == :html_attribute
            nil # Return nil to keep original node
          end
          ast
        end

        private

        # @rbs node: Herb::AST::HTMLAttributeNode
        # @rbs return: void
        def normalize_attribute(node)
          return unless node.value

          # TODO: Implement attribute value normalization
          # This requires modifying AST nodes in place or creating new nodes
          # For now, this is a placeholder
        end
      end
    end
  end
end
```

**Note:** Full AST mutation requires careful design. For now, we create the structure and defer full implementation until we clarify the AST modification API.

**Test Cases:**
```ruby
RSpec.describe Herb::Format::Rewriters::NormalizeAttributes do
  describe "class methods" do
    it "returns correct rewriter_name" do
      expect(described_class.rewriter_name).to eq("normalize-attributes")
    end

    it "returns description" do
      expect(described_class.description).to be_a(String)
    end

    it "returns :pre phase" do
      expect(described_class.phase).to eq(:pre)
    end
  end

  describe "#rewrite" do
    let(:rewriter) { described_class.new }
    let(:config) { build(:formatter_config) }
    let(:context) { build(:context, config: config, source: "") }

    it "returns the AST" do
      source = '<div class="test">content</div>'
      ast = Herb.parse(source).value

      result = rewriter.rewrite(ast, context)

      expect(result).to be_a(Herb::AST::DocumentNode)
    end

    # TODO: Add tests for actual transformations once AST modification API is finalized
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/rewriters/normalize_attributes_spec.rb`

---

### Task 4.4: Implement SortAttributes Rewriter

**Location:** `herb-format/lib/herb/format/rewriters/sort_attributes.rb`

- [ ] Create SortAttributes class extending Base
- [ ] Implement rewriter_name returning "sort-attributes"
- [ ] Implement description
- [ ] Implement phase returning :post
- [ ] Implement rewrite(ast, context) method
- [ ] Sort attributes alphabetically by name
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    module Rewriters
      # Alphabetically sort HTML attributes.
      class SortAttributes < Base
        # @rbs return: String
        def self.rewriter_name = "sort-attributes"

        # @rbs return: String
        def self.description = "Sort HTML attributes alphabetically"

        # @rbs return: Symbol
        def self.phase = :post

        # @rbs ast: Herb::AST::DocumentNode
        # @rbs context: Context
        # @rbs return: Herb::AST::DocumentNode
        def rewrite(ast, context)
          traverse(ast) do |node|
            sort_element_attributes(node) if node.type == :html_open_tag
            nil
          end
          ast
        end

        private

        # @rbs node: Herb::AST::HTMLOpenTagNode
        # @rbs return: void
        def sort_element_attributes(node)
          # TODO: Implement attribute sorting
          # This requires modifying AST node's attributes array
        end

        # @rbs attr: Herb::AST::HTMLAttributeNode
        # @rbs return: String
        def attribute_sort_key(attr)
          # Extract attribute name for sorting
          attr.name&.child_nodes&.first&.content || ""
        end
      end
    end
  end
end
```

**Test Cases:**
```ruby
RSpec.describe Herb::Format::Rewriters::SortAttributes do
  describe "class methods" do
    it "returns correct rewriter_name" do
      expect(described_class.rewriter_name).to eq("sort-attributes")
    end

    it "returns :post phase" do
      expect(described_class.phase).to eq(:post)
    end
  end

  describe "#rewrite" do
    let(:rewriter) { described_class.new }
    let(:config) { build(:formatter_config) }
    let(:context) { build(:context, config: config, source: "") }

    it "returns the AST" do
      source = '<div class="test" id="main">content</div>'
      ast = Herb.parse(source).value

      result = rewriter.rewrite(ast, context)

      expect(result).to be_a(Herb::AST::DocumentNode)
    end

    # TODO: Add tests for actual sorting once AST modification API is finalized
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/rewriters/sort_attributes_spec.rb`

---

### Task 4.5: Implement TailwindClassSorter Rewriter

**Location:** `herb-format/lib/herb/format/rewriters/tailwind_class_sorter.rb`

- [ ] Create TailwindClassSorter class extending Base
- [ ] Implement rewriter_name returning "tailwind-class-sorter"
- [ ] Implement description
- [ ] Implement phase returning :post
- [ ] Implement rewrite(ast, context) method
- [ ] Sort Tailwind CSS classes according to recommended order
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    module Rewriters
      # Sort Tailwind CSS classes according to recommended order.
      class TailwindClassSorter < Base
        # Tailwind class categories (simplified)
        CATEGORY_ORDER = {
          # Layout
          container: 0, block: 1, inline: 1, flex: 1, grid: 1,
          # Positioning
          static: 10, fixed: 10, absolute: 10, relative: 10,
          # Spacing
          m: 20, p: 20, mt: 21, mr: 21, mb: 21, ml: 21,
          pt: 21, pr: 21, pb: 21, pl: 21,
          # Sizing
          w: 30, h: 30,
          # Typography
          text: 40, font: 41,
          # Background
          bg: 50,
          # Border
          border: 60, rounded: 61,
          # Effects
          shadow: 70, opacity: 71
        }.freeze

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
          traverse(ast) do |node|
            if node.type == :html_attribute
              sort_class_attribute(node)
            end
            nil
          end
          ast
        end

        private

        # @rbs node: Herb::AST::HTMLAttributeNode
        # @rbs return: void
        def sort_class_attribute(node)
          # Check if this is a class attribute
          attr_name = node.name&.child_nodes&.first&.content
          return unless attr_name == "class"

          # TODO: Implement Tailwind class sorting
          # This requires modifying attribute value content
        end

        # @rbs class_name: String
        # @rbs return: Integer
        def tailwind_sort_key(class_name)
          # Extract category prefix (e.g., "mt-4" -> "mt")
          prefix = class_name.split("-").first
          CATEGORY_ORDER[prefix.to_sym] || 999
        end
      end
    end
  end
end
```

**Test Cases:**
```ruby
RSpec.describe Herb::Format::Rewriters::TailwindClassSorter do
  describe "class methods" do
    it "returns correct rewriter_name" do
      expect(described_class.rewriter_name).to eq("tailwind-class-sorter")
    end

    it "returns :post phase" do
      expect(described_class.phase).to eq(:post)
    end
  end

  describe "#rewrite" do
    let(:rewriter) { described_class.new }
    let(:config) { build(:formatter_config) }
    let(:context) { build(:context, config: config, source: "") }

    it "returns the AST" do
      source = '<div class="mt-4 flex bg-blue-500">content</div>'
      ast = Herb.parse(source).value

      result = rewriter.rewrite(ast, context)

      expect(result).to be_a(Herb::AST::DocumentNode)
    end

    # TODO: Add tests for actual sorting once AST modification API is finalized
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/rewriters/tailwind_class_sorter_spec.rb`

---

## Part C: Custom Rewriter Loader

### Task 4.6: Implement CustomRewriterLoader

**Location:** `herb-format/lib/herb/format/custom_rewriter_loader.rb`

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
# rbs_inline: enabled

module Herb
  module Format
    # Loads custom rewriter implementations from configured paths.
    #
    # @rbs config: Herb::Config::FormatterConfig
    # @rbs registry: RewriterRegistry
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

      # Load custom rewriters from configured path.
      #
      # Processing:
      # 1. Reads custom rewriter path (default: .herb/rewriters/*.rb)
      # 2. Requires Ruby files containing rewriter classes
      # 3. Auto-registers newly loaded rewriter classes with RewriterRegistry
      # 4. Handles load errors gracefully
      #
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

      # Auto-register newly loaded rewriter classes.
      # Scans Herb::Format::Rewriters module for new Base subclasses.
      #
      # @rbs return: void
      def auto_register_rewriters
        # Find all classes in Rewriters module
        Rewriters.constants.each do |const_name|
          const = Rewriters.const_get(const_name)
          next unless const.is_a?(Class) && const < Rewriters::Base

          # Skip if already registered
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

**Test Cases:**
```ruby
RSpec.describe Herb::Format::CustomRewriterLoader do
  let(:config) { build(:formatter_config) }
  let(:registry) { Herb::Format::RewriterRegistry.new }
  let(:loader) { described_class.new(config, registry) }

  describe "#load" do
    it "loads rewriters from .herb/rewriters/" do
      # This would require creating a temporary .herb/rewriters directory
      # with a test rewriter file
      # Skipped for now due to filesystem complexity
      pending "requires filesystem setup"
    end

    it "handles missing directory gracefully" do
      expect { loader.load }.not_to raise_error
    end

    it "handles file load errors gracefully" do
      # Create a directory with a broken rewriter file
      pending "requires filesystem setup"
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/custom_rewriter_loader_spec.rb`

---

## Part D: Integration

### Task 4.7: Wire Up Rewriter Components

**Location:** `herb-format/lib/herb/format.rb`

- [ ] Create lib/herb/format/rewriters.rb entry point
- [ ] Add require_relative for rewriters/base
- [ ] Add require_relative for rewriter_registry
- [ ] Add require_relative for custom_rewriter_loader
- [ ] Add require for rewriters.rb in lib/herb/format.rb
- [ ] Run rbs-inline to generate signatures
- [ ] Run steep check

**lib/herb/format/rewriters.rb:**
```ruby
# rbs_inline: enabled

require_relative "rewriters/base"
require_relative "rewriters/normalize_attributes"
require_relative "rewriters/sort_attributes"
require_relative "rewriters/tailwind_class_sorter"
```

**Verification:**
- `cd herb-format && ./bin/steep check` passes
- All rewriters can be required without error

---

### Task 4.8: Update Runner to Use Registry

**Note:** This task will be implemented in Phase 5 when we create the Runner class.

- [ ] Runner initializes RewriterRegistry
- [ ] Runner calls load_builtin_rewriters
- [ ] Runner calls CustomRewriterLoader.load
- [ ] FormatterFactory receives configured registry

---

### Task 4.9: Full Verification

- [ ] Run `cd herb-format && ./bin/rake` -- all checks pass
- [ ] Verify RewriterRegistry works correctly
- [ ] Verify built-in rewriters can be registered
- [ ] Verify FormatterFactory can instantiate rewriters
- [ ] Verify CustomRewriterLoader handles missing directory

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| 4.1 | A | Rewriter Base class |
| 4.2 | A | RewriterRegistry |
| 4.3 | B | NormalizeAttributes rewriter |
| 4.4 | B | SortAttributes rewriter |
| 4.5 | B | TailwindClassSorter rewriter |
| 4.6 | C | CustomRewriterLoader |
| 4.7-4.9 | D | Integration and verification |

**Total: 9 tasks**

## Design Notes

### AST Modification API

The current implementation has placeholder rewriter logic because the `herb` gem's AST may not support in-place modification. We have several options:

1. **Immutable AST with rebuilding** - Create new AST nodes with modifications
2. **Mutable AST** - Modify AST nodes in place (requires herb gem support)
3. **AST transformation library** - Build a transformation layer on top of herb AST

**Recommendation:** Start with option 1 (rebuild nodes) using the existing AST structure. This is the safest approach and doesn't require changes to the herb gem.

The rewriter implementations in this phase establish the structure and interface. Full AST transformation logic can be added incrementally as we test each rewriter.

## Related Documents

- [herb-format Design](../design/herb-format-design.md)
- [Phase 3: Formatter Core](./phase-3-formatter-core.md)
- [Phase 5: Runner](./phase-5-formatter-runner.md)
