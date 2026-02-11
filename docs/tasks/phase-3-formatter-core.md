# Phase 3: Formatter Core

This phase implements the FormatIgnore directive detection, the core Formatter class, and the FormatterFactory.

**Design document:** [herb-format-design.md](../design/herb-format-design.md) (FormatIgnore, Formatter, FormatterFactory sections)

**Reference:** TypeScript `@herb-tools/formatter` Formatter and FormatIgnore implementations

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| FormatIgnore | Detect `<%# herb:formatter ignore %>` directives | Allows files to opt-out of formatting |
| Formatter | Core formatting orchestration | Coordinates parsing, ignore detection, rewriters, engine |
| FormatterFactory | Create configured Formatter instances | Factory pattern for clean instantiation |

## Prerequisites

- Phase 1 complete (Foundation)
- Phase 2 complete (Engine)
- herb gem available (Herb.parse, Herb::Visitor)

## Design Principles

1. **AST-based ignore detection** - Parse first, then check for directive in AST
2. **Single formatter entry point** - Formatter.format() handles entire pipeline
3. **Factory pattern** - FormatterFactory creates configured instances
4. **Error resilience** - Parse errors return source unchanged

---

## Part A: FormatIgnore

### Task 3.1: Create FormatIgnore Module

**Location:** `herb-format/lib/herb/format/format_ignore.rb`

- [ ] Create FormatIgnore module
- [ ] Define FORMATTER_IGNORE_COMMENT constant
- [ ] Implement self.ignore?(document) class method
- [ ] Implement self.ignore_comment?(node) helper method
- [ ] Create IgnoreDetector visitor class
- [ ] Add RBS inline type annotations
- [ ] Create spec file with comprehensive tests

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Detects `<%# herb:formatter ignore %>` directives in a parsed AST.
    #
    # The TypeScript reference implementation (format-ignore.ts) handles formatter
    # directive detection within the formatter package itself. The Ruby implementation
    # follows this same pattern, keeping the ignore detection logic self-contained.
    module FormatIgnore
      FORMATTER_IGNORE_COMMENT = "herb:formatter ignore"

      # Check if the AST contains a herb:formatter ignore directive.
      # Traverses ERB comment nodes looking for an exact match.
      #
      # @rbs document: Herb::AST::DocumentNode
      # @rbs return: bool
      def self.ignore?(document)
        detector = IgnoreDetector.new
        document.accept(detector)
        detector.ignore_directive_found
      end

      # Check if a single node is a herb:formatter ignore comment.
      #
      # @rbs node: Herb::AST::Node
      # @rbs return: bool
      def self.ignore_comment?(node)
        return false unless node.type == :erb_content

        # ERBContentNode has a content token
        content = node.content&.value
        return false unless content

        content.strip == FORMATTER_IGNORE_COMMENT
      end

      # Internal Visitor subclass that traverses the AST to detect
      # the ignore directive. Sets a flag when found.
      #
      # @rbs!
      #   class IgnoreDetector < Herb::Visitor
      #     @ignore_directive_found: bool
      #
      #     attr_reader ignore_directive_found: bool
      #
      #     def initialize: () -> void
      #     def visit_erb_content_node: (Herb::AST::ERBContentNode node) -> void
      #   end
      class IgnoreDetector < Herb::Visitor
        attr_reader :ignore_directive_found

        # @rbs return: void
        def initialize
          super()
          @ignore_directive_found = false
        end

        # @rbs node: Herb::AST::ERBContentNode
        # @rbs return: void
        def visit_erb_content_node(node)
          # Check if this is an ERB comment (<%# ... %>)
          tag_opening = node.tag_opening&.value
          return unless tag_opening == "<%#"

          # Check if content matches the ignore directive
          if FormatIgnore.ignore_comment?(node)
            @ignore_directive_found = true
          end

          super # Continue visiting children
        end
      end
    end
  end
end
```

**Test Cases:**
```ruby
RSpec.describe Herb::Format::FormatIgnore do
  describe ".ignore?" do
    it "returns true when file contains herb:formatter ignore directive" do
      source = "<%# herb:formatter ignore %>\n<div>test</div>"
      document = Herb.parse(source).value
      expect(described_class.ignore?(document)).to be true
    end

    it "returns false when file does not contain directive" do
      source = "<div>test</div>"
      document = Herb.parse(source).value
      expect(described_class.ignore?(document)).to be false
    end

    it "returns false when file contains other comments" do
      source = "<%# This is a comment %>\n<div>test</div>"
      document = Herb.parse(source).value
      expect(described_class.ignore?(document)).to be false
    end

    it "handles directive with extra whitespace" do
      source = "<%#  herb:formatter ignore  %>\n<div>test</div>"
      document = Herb.parse(source).value
      expect(described_class.ignore?(document)).to be true
    end

    it "detects directive not at the beginning of file" do
      source = "<div>\n  <%# herb:formatter ignore %>\n</div>"
      document = Herb.parse(source).value
      expect(described_class.ignore?(document)).to be true
    end

    it "returns false for non-ignore herb comments" do
      source = "<%# herb:formatter something %>\n<div>test</div>"
      document = Herb.parse(source).value
      expect(described_class.ignore?(document)).to be false
    end
  end

  describe ".ignore_comment?" do
    it "returns true for ignore comment node" do
      source = "<%# herb:formatter ignore %>"
      node = Herb.parse(source).value.child_nodes.first
      expect(described_class.ignore_comment?(node)).to be true
    end

    it "returns false for non-ignore comment" do
      source = "<%# other comment %>"
      node = Herb.parse(source).value.child_nodes.first
      expect(described_class.ignore_comment?(node)).to be false
    end

    it "returns false for non-comment node" do
      source = "<div>test</div>"
      node = Herb.parse(source).value.child_nodes.first
      expect(described_class.ignore_comment?(node)).to be false
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/format_ignore_spec.rb`
- All tests pass

---

## Part B: Formatter

### Task 3.2: Create Formatter Class

**Location:** `herb-format/lib/herb/format/formatter.rb`

- [ ] Create Formatter class
- [ ] Add initialize with engine, pre_rewriters, post_rewriters, config
- [ ] Implement format(file_path, source, force:) method
- [ ] Handle parse errors gracefully (return source unchanged)
- [ ] Check for ignore directive (unless force: true)
- [ ] Apply pre-rewriters, engine, post-rewriters pipeline
- [ ] Return FormatResult
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Core single-file formatting implementation.
    #
    # @rbs engine: Engine
    # @rbs pre_rewriters: Array[Rewriters::Base]
    # @rbs post_rewriters: Array[Rewriters::Base]
    # @rbs config: Herb::Config::FormatterConfig
    class Formatter
      attr_reader :engine, :pre_rewriters, :post_rewriters, :config

      # @rbs engine: Engine
      # @rbs pre_rewriters: Array[Rewriters::Base]
      # @rbs post_rewriters: Array[Rewriters::Base]
      # @rbs config: Herb::Config::FormatterConfig
      # @rbs return: void
      def initialize(engine, pre_rewriters, post_rewriters, config)
        @engine = engine
        @pre_rewriters = pre_rewriters
        @post_rewriters = post_rewriters
        @config = config
      end

      # Format a single file and return result.
      #
      # Processing flow:
      # 1. Parse ERB template into AST via Herb.parse
      # 2. If parsing fails, return source unchanged with error
      # 3. Check for ignore directive via FormatIgnore.ignore? (unless force)
      # 4. If ignored, return source unchanged with ignored flag
      # 5. Create Context with source and configuration
      # 6. Execute pre-rewriters (in order)
      # 7. Apply formatting rules via Engine
      # 8. Execute post-rewriters (in order)
      # 9. Return FormatResult with original and formatted content
      #
      # @rbs file_path: String
      # @rbs source: String
      # @rbs force: bool
      # @rbs return: FormatResult
      def format(file_path, source, force: false)
        # Parse
        parse_result = Herb.parse(source)

        # Handle parse errors
        if parse_result.errors.any?
          error = Errors::ParseError.new("Failed to parse #{file_path}: #{parse_result.errors.first.message}")
          return FormatResult.new(
            file_path: file_path,
            original: source,
            formatted: source,
            error: error
          )
        end

        ast = parse_result.value

        # Check for ignore directive (unless force)
        unless force
          if FormatIgnore.ignore?(ast)
            return FormatResult.new(
              file_path: file_path,
              original: source,
              formatted: source,
              ignored: true
            )
          end
        end

        # Create context
        context = Context.new(file_path: file_path, source: source, config: config)

        begin
          # Apply pre-rewriters
          ast = apply_rewriters(ast, pre_rewriters, context)

          # Apply formatting engine
          formatted = engine.format(ast, context)

          # TODO: Apply post-rewriters on AST after engine?
          # Note: Engine returns String, not AST, so post-rewriters
          # would need to re-parse. This needs design clarification.
          # For now, skip post-rewriters in engine phase.

          FormatResult.new(
            file_path: file_path,
            original: source,
            formatted: formatted
          )
        rescue StandardError => e
          FormatResult.new(
            file_path: file_path,
            original: source,
            formatted: source,
            error: e
          )
        end
      end

      private

      # Apply rewriters to AST in order.
      #
      # @rbs ast: Herb::AST::DocumentNode
      # @rbs rewriters: Array[Rewriters::Base]
      # @rbs context: Context
      # @rbs return: Herb::AST::DocumentNode
      def apply_rewriters(ast, rewriters, context)
        rewriters.reduce(ast) do |current_ast, rewriter|
          rewriter.rewrite(current_ast, context)
        end
      end
    end
  end
end
```

**Design Note:**

The current design has a challenge: the Engine returns a String (formatted source), but post-rewriters need an AST to transform. There are two options:

1. **Re-parse after engine** - Parse the formatted string back to AST, apply post-rewriters, serialize again
2. **Engine returns AST** - Engine modifies AST in place, serialize at the end

The TypeScript reference uses option 2: rewriters transform the AST, and serialization happens once at the end. We should update the Engine design to return AST instead of String.

For now, we'll note this as a TODO and implement post-rewriters after clarifying the design.

**Test Cases:**
```ruby
RSpec.describe Herb::Format::Formatter do
  let(:engine) { build(:engine) }
  let(:pre_rewriters) { [] }
  let(:post_rewriters) { [] }
  let(:config) { build(:formatter_config) }
  let(:formatter) { described_class.new(engine, pre_rewriters, post_rewriters, config) }

  describe "#format" do
    it "returns FormatResult with formatted content" do
      source = "<div>test</div>"
      result = formatter.format("test.erb", source)

      expect(result).to be_a(Herb::Format::FormatResult)
      expect(result.file_path).to eq("test.erb")
      expect(result.original).to eq(source)
    end

    it "returns source unchanged when parse fails" do
      source = "<div><span></div>" # malformed
      result = formatter.format("test.erb", source)

      expect(result.formatted).to eq(source)
      expect(result.error?).to be true
    end

    it "returns source unchanged when file is ignored" do
      source = "<%# herb:formatter ignore %>\n<div>test</div>"
      result = formatter.format("test.erb", source, force: false)

      expect(result.formatted).to eq(source)
      expect(result.ignored?).to be true
    end

    it "formats file when force: true even if ignored" do
      source = "<%# herb:formatter ignore %>\n<div>test</div>"
      result = formatter.format("test.erb", source, force: true)

      expect(result.ignored?).to be false
      # Should be formatted
    end

    it "applies pre-rewriters before engine" do
      # Test with mock rewriter
      rewriter = instance_double(Herb::Format::Rewriters::Base)
      allow(rewriter).to receive(:rewrite) { |ast, _ctx| ast }

      formatter_with_rewriter = described_class.new(engine, [rewriter], [], config)
      source = "<div>test</div>"
      formatter_with_rewriter.format("test.erb", source)

      expect(rewriter).to have_received(:rewrite)
    end

    it "handles formatter errors gracefully" do
      allow(engine).to receive(:format).and_raise(StandardError.new("Engine error"))

      source = "<div>test</div>"
      result = formatter.format("test.erb", source)

      expect(result.error?).to be true
      expect(result.formatted).to eq(source) # Returns original on error
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/formatter_spec.rb`
- All tests pass

---

## Part C: FormatterFactory

### Task 3.3: Create FormatterFactory Class

**Location:** `herb-format/lib/herb/format/formatter_factory.rb`

- [ ] Create FormatterFactory class
- [ ] Add initialize with config and rewriter_registry
- [ ] Implement create() method returning configured Formatter
- [ ] Implement private build_engine() method
- [ ] Implement private build_pre_rewriters() method
- [ ] Implement private build_post_rewriters() method
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Creates configured Formatter instances (Factory Pattern).
    #
    # @rbs config: Herb::Config::FormatterConfig
    # @rbs rewriter_registry: RewriterRegistry
    class FormatterFactory
      attr_reader :config, :rewriter_registry

      # @rbs config: Herb::Config::FormatterConfig
      # @rbs rewriter_registry: RewriterRegistry
      # @rbs return: void
      def initialize(config, rewriter_registry)
        @config = config
        @rewriter_registry = rewriter_registry
      end

      # Create a configured Formatter instance.
      #
      # Processing:
      # 1. Create Engine with indent_width and max_line_length configuration
      # 2. Query RewriterRegistry for configured pre-rewriters
      # 3. Query RewriterRegistry for configured post-rewriters
      # 4. Instantiate each rewriter
      # 5. Create Formatter with engine and rewriters
      #
      # @rbs return: Formatter
      def create
        engine = build_engine
        pre_rewriters = build_pre_rewriters
        post_rewriters = build_post_rewriters

        Formatter.new(engine, pre_rewriters, post_rewriters, config)
      end

      private

      # @rbs return: Engine
      def build_engine
        Engine.new(
          indent_width: config.indent_width,
          max_line_length: config.max_line_length
        )
      end

      # @rbs return: Array[Rewriters::Base]
      def build_pre_rewriters
        config.rewriter_pre.map do |name|
          instantiate_rewriter(name)
        end.compact
      end

      # @rbs return: Array[Rewriters::Base]
      def build_post_rewriters
        config.rewriter_post.map do |name|
          instantiate_rewriter(name)
        end.compact
      end

      # @rbs name: String
      # @rbs return: Rewriters::Base?
      def instantiate_rewriter(name)
        rewriter_class = rewriter_registry.get(name)
        return nil unless rewriter_class

        rewriter_class.new
      rescue StandardError => e
        warn "Failed to instantiate rewriter '#{name}': #{e.message}"
        nil
      end
    end
  end
end
```

**Test Cases:**
```ruby
RSpec.describe Herb::Format::FormatterFactory do
  let(:config) { build(:formatter_config, indent_width: 4, max_line_length: 120) }
  let(:rewriter_registry) { instance_double(Herb::Format::RewriterRegistry) }
  let(:factory) { described_class.new(config, rewriter_registry) }

  describe "#create" do
    before do
      allow(rewriter_registry).to receive(:get).and_return(nil)
    end

    it "creates a Formatter instance" do
      formatter = factory.create

      expect(formatter).to be_a(Herb::Format::Formatter)
    end

    it "creates engine with correct configuration" do
      formatter = factory.create

      expect(formatter.engine.indent_width).to eq(4)
      expect(formatter.engine.max_line_length).to eq(120)
    end

    it "builds pre-rewriters from config" do
      config_with_rewriters = build(:formatter_config, rewriter_pre: ["normalize-attributes"])
      rewriter_class = Class.new(Herb::Format::Rewriters::Base)
      allow(rewriter_registry).to receive(:get).with("normalize-attributes").and_return(rewriter_class)

      factory_with_rewriters = described_class.new(config_with_rewriters, rewriter_registry)
      formatter = factory_with_rewriters.create

      expect(formatter.pre_rewriters.size).to eq(1)
    end

    it "builds post-rewriters from config" do
      config_with_rewriters = build(:formatter_config, rewriter_post: ["tailwind-class-sorter"])
      rewriter_class = Class.new(Herb::Format::Rewriters::Base)
      allow(rewriter_registry).to receive(:get).with("tailwind-class-sorter").and_return(rewriter_class)

      factory_with_rewriters = described_class.new(config_with_rewriters, rewriter_registry)
      formatter = factory_with_rewriters.create

      expect(formatter.post_rewriters.size).to eq(1)
    end

    it "skips unknown rewriters" do
      config_with_rewriters = build(:formatter_config, rewriter_pre: ["unknown-rewriter"])
      allow(rewriter_registry).to receive(:get).with("unknown-rewriter").and_return(nil)

      factory_with_rewriters = described_class.new(config_with_rewriters, rewriter_registry)
      formatter = factory_with_rewriters.create

      expect(formatter.pre_rewriters).to be_empty
    end

    it "handles rewriter instantiation errors gracefully" do
      config_with_rewriters = build(:formatter_config, rewriter_pre: ["broken-rewriter"])
      rewriter_class = Class.new(Herb::Format::Rewriters::Base) do
        def initialize
          raise StandardError, "Initialization failed"
        end
      end
      allow(rewriter_registry).to receive(:get).with("broken-rewriter").and_return(rewriter_class)

      factory_with_rewriters = described_class.new(config_with_rewriters, rewriter_registry)

      expect {
        formatter = factory_with_rewriters.create
        expect(formatter.pre_rewriters).to be_empty
      }.to output(/Failed to instantiate rewriter/).to_stderr
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/formatter_factory_spec.rb`
- All tests pass

---

## Part D: Integration

### Task 3.4: Wire Up Phase 3 Components

**Location:** `herb-format/lib/herb/format.rb`

- [ ] Add require_relative for format_ignore
- [ ] Add require_relative for formatter
- [ ] Add require_relative for formatter_factory
- [ ] Run rbs-inline to generate signatures
- [ ] Run steep check

**Verification:**
- `cd herb-format && ./bin/steep check` passes
- No require errors

---

### Task 3.5: Create Integration Tests

**Location:** `herb-format/spec/herb/format/integration_spec.rb`

- [ ] Create integration test file
- [ ] Test full formatting pipeline (parse → ignore check → format)
- [ ] Test with various AST structures
- [ ] Test error handling

**Example:**
```ruby
RSpec.describe "Formatting Pipeline Integration" do
  let(:config) { build(:formatter_config, indent_width: 2, max_line_length: 80) }
  let(:registry) { Herb::Format::RewriterRegistry.new }
  let(:factory) { Herb::Format::FormatterFactory.new(config, registry) }
  let(:formatter) { factory.create }

  it "formats simple HTML correctly" do
    source = "<div><p>Hello</p></div>"
    result = formatter.format("test.erb", source)

    expect(result.changed?).to be true
    expect(result.formatted).to include("  <p>") # Indented
  end

  it "ignores files with directive" do
    source = "<%# herb:formatter ignore %>\n<div><p>Hello</p></div>"
    result = formatter.format("test.erb", source)

    expect(result.ignored?).to be true
    expect(result.formatted).to eq(source)
  end

  it "handles parse errors" do
    source = "<div><span></div>"
    result = formatter.format("test.erb", source)

    expect(result.error?).to be true
    expect(result.formatted).to eq(source)
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/integration_spec.rb`
- All tests pass

---

### Task 3.6: Full Verification

- [ ] Run `cd herb-format && ./bin/rake` -- all checks pass
- [ ] Verify FormatIgnore detects directives correctly
- [ ] Verify Formatter handles all code paths (success, ignored, error)
- [ ] Verify FormatterFactory creates properly configured instances
- [ ] Verify integration tests pass

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| 3.1 | A | FormatIgnore module and IgnoreDetector |
| 3.2 | B | Formatter class |
| 3.3 | C | FormatterFactory class |
| 3.4-3.6 | D | Integration and verification |

**Total: 6 tasks**

## Design Notes

### Engine Output Type Issue

The current Engine implementation returns a String, but post-rewriters need an AST to transform. We have two options:

1. **Re-parse after engine** - Not ideal (performance, potential parse errors)
2. **Engine returns modified AST** - Better design, matches TypeScript reference

**Recommendation:** Update Engine in Phase 2 to modify AST in place and return AST. Add a separate serialization step in Formatter using herb-printer's IdentityPrinter.

This would change the Formatter flow to:
```ruby
# Apply pre-rewriters (AST → AST)
ast = apply_rewriters(ast, pre_rewriters, context)

# Apply formatting engine (AST → AST)
ast = engine.format(ast, context)

# Apply post-rewriters (AST → AST)
ast = apply_rewriters(ast, post_rewriters, context)

# Serialize AST to string
formatted = Herb::Printer::IdentityPrinter.print(ast)
```

This can be addressed in a future refinement phase or as part of Phase 4 (Rewriters).

## Related Documents

- [herb-format Design](../design/herb-format-design.md)
- [Phase 1: Foundation](./phase-1-formatter-foundation.md)
- [Phase 2: Engine](./phase-2-formatter-engine.md)
- [Phase 4: Rewriters](./phase-4-formatter-rewriters.md)
