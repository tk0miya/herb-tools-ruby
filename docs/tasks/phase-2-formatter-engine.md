# Phase 2: Formatter Engine

This phase implements the core formatting engine that traverses the AST and applies formatting rules.

**Design document:** [herb-format-design.md](../design/herb-format-design.md) (Engine section)

**Reference:** TypeScript `@herb-tools/formatter` Engine implementation

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| Engine class | Core AST formatting logic | Central formatting implementation |
| HTML formatting | Format HTML elements, attributes, text | Core HTML support |
| ERB formatting | Format ERB tags and control structures | ERB template support |
| Whitespace handling | Normalize indentation and whitespace | Clean, consistent output |

## Prerequisites

- Phase 1 complete (Foundation, data structures, configuration)
- herb-printer gem available (for serialization reference)
- herb gem available (for AST node types)

## Design Principles

1. **AST traversal** - Engine extends or uses visitor pattern for traversal
2. **Stateless formatting** - Each format() call is independent
3. **Preserved content** - Do not reformat `<pre>`, `<code>`, `<script>`, `<style>`
4. **Lossless transformation** - Maintain semantic meaning of source

---

## Part A: Engine Foundation

### Task 2.1: Create Engine Class

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Create Engine class
- [ ] Add initialize with indent_width and max_line_length parameters
- [ ] Add format(ast, context) method returning String
- [ ] Add private visit(node, depth) recursive traversal method
- [ ] Add helper methods: indent(depth), is_void_element?, is_preserved_element?
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Core formatting engine that traverses AST and applies formatting rules.
    #
    # @rbs indent_width: Integer
    # @rbs max_line_length: Integer
    class Engine
      VOID_ELEMENTS = %w[
        area base br col embed hr img input link meta param source track wbr
      ].freeze

      PRESERVED_ELEMENTS = %w[pre code script style].freeze

      attr_reader :indent_width, :max_line_length

      # @rbs indent_width: Integer
      # @rbs max_line_length: Integer
      # @rbs return: void
      def initialize(indent_width:, max_line_length:)
        @indent_width = indent_width
        @max_line_length = max_line_length
      end

      # Format AST and return formatted string.
      #
      # @rbs ast: Herb::AST::DocumentNode
      # @rbs context: Context
      # @rbs return: String
      def format(ast, context)
        @context = context
        @output = String.new
        visit(ast, depth: 0)
        @output
      end

      private

      # @rbs node: Herb::AST::Node
      # @rbs depth: Integer
      # @rbs return: void
      def visit(node, depth:)
        case node.type
        when :document
          format_document(node, depth)
        when :html_element
          format_element(node, depth)
        when :html_text
          format_text(node, depth)
        # ... other node types will be added in subsequent tasks
        else
          # Fallback: use IdentityPrinter for unknown nodes
          @output << Herb::Printer::IdentityPrinter.print(node)
        end
      end

      # @rbs depth: Integer
      # @rbs return: String
      def indent(depth)
        " " * (indent_width * depth)
      end

      # @rbs tag_name: String
      # @rbs return: bool
      def is_void_element?(tag_name)
        VOID_ELEMENTS.include?(tag_name.downcase)
      end

      # @rbs tag_name: String
      # @rbs return: bool
      def is_preserved_element?(tag_name)
        PRESERVED_ELEMENTS.include?(tag_name.downcase)
      end
    end
  end
end
```

**Test Cases:**
- Engine initializes with indent_width and max_line_length
- format() returns a String
- indent(0) returns ""
- indent(1) returns correct number of spaces
- is_void_element?("br") returns true
- is_void_element?("div") returns false
- is_preserved_element?("pre") returns true

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`

---

## Part B: HTML Formatting

### Task 2.2: Implement Document and Text Formatting

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Implement format_document(node, depth)
- [ ] Implement format_text(node, depth)
- [ ] Implement format_whitespace(node, depth)
- [ ] Implement format_literal(node, depth)
- [ ] Add test cases for each method

**Implementation:**
```ruby
private

# @rbs node: Herb::AST::DocumentNode
# @rbs depth: Integer
# @rbs return: void
def format_document(node, depth)
  node.child_nodes.each do |child|
    visit(child, depth: depth)
  end
end

# @rbs node: Herb::AST::HTMLTextNode
# @rbs depth: Integer
# @rbs return: void
def format_text(node, depth)
  # Preserve text content as-is
  @output << node.content
end

# @rbs node: Herb::AST::WhitespaceNode
# @rbs depth: Integer
# @rbs return: void
def format_whitespace(node, depth)
  # Preserve whitespace as-is for now
  # (Future: normalize whitespace based on context)
  @output << node.value.value
end

# @rbs node: Herb::AST::LiteralNode
# @rbs depth: Integer
# @rbs return: void
def format_literal(node, depth)
  @output << node.content
end
```

**Test Cases:**
- format_document visits all children
- format_text preserves text content
- format_whitespace preserves whitespace
- format_literal preserves literal content

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`
- Basic document with text formats correctly

---

### Task 2.3: Implement Element Formatting

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Implement format_element(node, depth)
- [ ] Implement format_open_tag(node, depth)
- [ ] Implement format_close_tag(node, depth)
- [ ] Handle void elements (no close tag)
- [ ] Handle preserved elements (no indentation changes)
- [ ] Add test cases

**Implementation:**
```ruby
private

# @rbs node: Herb::AST::HTMLElementNode
# @rbs depth: Integer
# @rbs return: void
def format_element(node, depth)
  tag_name = node.tag_name&.value || ""
  preserved = is_preserved_element?(tag_name)

  # Format opening tag
  visit(node.open_tag, depth: depth)

  # Format body (skip if void element)
  unless is_void_element?(tag_name)
    if preserved
      # Preserve content as-is for <pre>, <code>, etc.
      node.body.each do |child|
        @output << Herb::Printer::IdentityPrinter.print(child)
      end
    else
      # Format body with increased depth
      node.body.each do |child|
        visit(child, depth: depth + 1)
      end
    end

    # Format closing tag
    visit(node.close_tag, depth: depth) if node.close_tag
  end
end

# @rbs node: Herb::AST::HTMLOpenTagNode
# @rbs depth: Integer
# @rbs return: void
def format_open_tag(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "<"

  # Visit tag_opening and tag_name (these are in child_nodes)
  node.child_nodes.each do |child|
    case child.type
    when :html_attribute_name
      @output << node.tag_name.value if node.tag_name
    when :html_attribute
      @output << " "
      visit(child, depth: depth)
    when :whitespace
      # Skip whitespace in attributes for now
    else
      visit(child, depth: depth)
    end
  end

  @output << ">"
end

# @rbs node: Herb::AST::HTMLCloseTagNode
# @rbs depth: Integer
# @rbs return: void
def format_close_tag(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "</"
  @output << node.tag_name.value if node.tag_name
  @output << ">"
end

# @rbs node: Herb::AST::Node
# @rbs return: bool
def should_indent?(node)
  # Determine if node should be indented
  # (Future: track context like "previous was newline")
  true
end
```

**Test Cases:**
- format_element with void element (no close tag)
- format_element with preserved element (content unchanged)
- format_element with normal element (body indented)
- format_open_tag outputs correct structure
- format_close_tag outputs correct structure

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`
- Basic HTML elements format correctly

---

### Task 2.4: Implement Attribute Formatting

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Implement format_attribute(node, depth)
- [ ] Implement format_attribute_name(node, depth)
- [ ] Implement format_attribute_value(node, depth)
- [ ] Handle boolean attributes (no value)
- [ ] Handle quoted values (preserve double quotes)
- [ ] Add test cases

**Implementation:**
```ruby
private

# @rbs node: Herb::AST::HTMLAttributeNode
# @rbs depth: Integer
# @rbs return: void
def format_attribute(node, depth)
  visit(node.name, depth: depth)

  if node.value
    @output << "="
    visit(node.value, depth: depth)
  end
end

# @rbs node: Herb::AST::HTMLAttributeNameNode
# @rbs depth: Integer
# @rbs return: void
def format_attribute_name(node, depth)
  node.child_nodes.each do |child|
    visit(child, depth: depth)
  end
end

# @rbs node: Herb::AST::HTMLAttributeValueNode
# @rbs depth: Integer
# @rbs return: void
def format_attribute_value(node, depth)
  # Always use double quotes
  @output << '"'

  node.child_nodes.each do |child|
    visit(child, depth: depth)
  end

  @output << '"'
end
```

**Test Cases:**
- format_attribute with value outputs name="value"
- format_attribute without value outputs name only
- format_attribute_value uses double quotes
- Attributes with ERB expressions format correctly

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`
- Attributes format correctly

---

### Task 2.5: Implement Comment and Special Node Formatting

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Implement format_comment(node, depth)
- [ ] Implement format_doctype(node, depth)
- [ ] Implement format_xml_declaration(node, depth)
- [ ] Implement format_cdata(node, depth)
- [ ] Add test cases

**Implementation:**
```ruby
private

# @rbs node: Herb::AST::HTMLCommentNode
# @rbs depth: Integer
# @rbs return: void
def format_comment(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "<!--"

  node.child_nodes.each do |child|
    visit(child, depth: depth)
  end

  @output << "-->"
end

# @rbs node: Herb::AST::HTMLDoctypeNode
# @rbs depth: Integer
# @rbs return: void
def format_doctype(node, depth)
  # Preserve DOCTYPE as-is
  @output << Herb::Printer::IdentityPrinter.print(node)
end

# @rbs node: Herb::AST::XMLDeclarationNode
# @rbs depth: Integer
# @rbs return: void
def format_xml_declaration(node, depth)
  # Preserve XML declaration as-is
  @output << Herb::Printer::IdentityPrinter.print(node)
end

# @rbs node: Herb::AST::CDATANode
# @rbs depth: Integer
# @rbs return: void
def format_cdata(node, depth)
  # Preserve CDATA as-is
  @output << Herb::Printer::IdentityPrinter.print(node)
end
```

**Test Cases:**
- format_comment preserves content
- format_doctype preserves content
- format_xml_declaration preserves content
- format_cdata preserves content

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`
- Special nodes format correctly

---

## Part C: ERB Formatting

### Task 2.6: Implement ERB Content Formatting

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Implement format_erb_content(node, depth)
- [ ] Implement format_erb_yield(node, depth)
- [ ] Implement format_erb_end(node, depth)
- [ ] Normalize ERB tag spacing (<%= %> not <%=  %>)
- [ ] Add test cases

**Implementation:**
```ruby
private

# @rbs node: Herb::AST::ERBContentNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_content(node, depth)
  tag_opening = node.tag_opening.value
  content = node.content.value.strip
  tag_closing = node.tag_closing.value

  # Normalize spacing: ensure single space after opening and before closing
  case tag_opening
  when "<%="
    @output << "<%= #{content} %>"
  when "<%"
    @output << "<% #{content} %>"
  when "<%#"
    @output << "<%# #{content} %>"
  else
    # Preserve unknown tag types
    @output << "#{tag_opening}#{content}#{tag_closing}"
  end
end

# @rbs node: Herb::AST::ERBYieldNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_yield(node, depth)
  # <%= yield %> is treated like ERBContentNode
  format_erb_content(node, depth)
end

# @rbs node: Herb::AST::ERBEndNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_end(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "<% end %>"
end
```

**Test Cases:**
- format_erb_content normalizes spacing
- format_erb_content with extra whitespace is normalized
- format_erb_yield formats correctly
- format_erb_end formats correctly

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`
- ERB expressions format correctly

---

### Task 2.7: Implement ERB Block Formatting

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Implement format_erb_block(node, depth)
- [ ] Format block opening tag
- [ ] Format block body (statements)
- [ ] Format block end tag
- [ ] Add test cases

**Implementation:**
```ruby
private

# @rbs node: Herb::AST::ERBBlockNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_block(node, depth)
  @output << indent(depth) if should_indent?(node)

  # Format opening tag (e.g., <% items.each do |item| %>)
  tag_opening = node.tag_opening.value
  content = node.content.value.strip
  tag_closing = node.tag_closing.value
  @output << "#{tag_opening} #{content} #{tag_closing}"

  # Format body
  node.statements.each do |stmt|
    visit(stmt, depth: depth + 1)
  end

  # Format end tag
  visit(node.end_node, depth: depth) if node.end_node
end
```

**Test Cases:**
- format_erb_block formats opening and end
- format_erb_block indents body
- Nested blocks increase depth correctly

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`
- ERB blocks format correctly

---

### Task 2.8: Implement ERB Control Flow Formatting

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Implement format_erb_if(node, depth)
- [ ] Implement format_erb_else(node, depth)
- [ ] Implement format_erb_unless(node, depth)
- [ ] Implement format_erb_case(node, depth)
- [ ] Implement format_erb_when(node, depth)
- [ ] Implement format_erb_while(node, depth)
- [ ] Implement format_erb_until(node, depth)
- [ ] Implement format_erb_for(node, depth)
- [ ] Add test cases for each

**Implementation:**
```ruby
private

# @rbs node: Herb::AST::ERBIfNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_if(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "<% if #{node.content.value.strip} %>"

  node.statements.each { |stmt| visit(stmt, depth: depth + 1) }

  # Handle elsif clauses
  node.subsequent.each do |clause|
    visit(clause, depth: depth)
  end

  # Handle else clause
  visit(node.else_clause, depth: depth) if node.else_clause

  visit(node.end_node, depth: depth) if node.end_node
end

# @rbs node: Herb::AST::ERBElseNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_else(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "<% else %>"

  node.statements.each { |stmt| visit(stmt, depth: depth + 1) }
end

# @rbs node: Herb::AST::ERBUnlessNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_unless(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "<% unless #{node.content.value.strip} %>"

  node.statements.each { |stmt| visit(stmt, depth: depth + 1) }

  visit(node.else_clause, depth: depth) if node.else_clause
  visit(node.end_node, depth: depth) if node.end_node
end

# Similar implementations for case/when, while, until, for...
```

**Test Cases:**
- format_erb_if formats if/elsif/else/end correctly
- format_erb_unless formats correctly
- format_erb_case and format_erb_when format correctly
- format_erb_while and format_erb_until format correctly
- Nested control flow maintains correct indentation

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`
- ERB control flow formats correctly

---

### Task 2.9: Implement ERB Exception Handling Formatting

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Implement format_erb_begin(node, depth)
- [ ] Implement format_erb_rescue(node, depth)
- [ ] Implement format_erb_ensure(node, depth)
- [ ] Add test cases

**Implementation:**
```ruby
private

# @rbs node: Herb::AST::ERBBeginNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_begin(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "<% begin %>"

  node.statements.each { |stmt| visit(stmt, depth: depth + 1) }

  node.rescue_clause.each { |clause| visit(clause, depth: depth) }
  visit(node.else_clause, depth: depth) if node.else_clause
  visit(node.ensure_clause, depth: depth) if node.ensure_clause
  visit(node.end_node, depth: depth) if node.end_node
end

# @rbs node: Herb::AST::ERBRescueNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_rescue(node, depth)
  @output << indent(depth) if should_indent?(node)
  content = node.content.value.strip
  if content.empty?
    @output << "<% rescue %>"
  else
    @output << "<% rescue #{content} %>"
  end

  node.statements.each { |stmt| visit(stmt, depth: depth + 1) }
end

# @rbs node: Herb::AST::ERBEnsureNode
# @rbs depth: Integer
# @rbs return: void
def format_erb_ensure(node, depth)
  @output << indent(depth) if should_indent?(node)
  @output << "<% ensure %>"

  node.statements.each { |stmt| visit(stmt, depth: depth + 1) }
end
```

**Test Cases:**
- format_erb_begin formats begin/rescue/ensure/end correctly
- format_erb_rescue with exception class formats correctly
- format_erb_rescue without exception class formats correctly
- Nested exception handling maintains correct indentation

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/engine_spec.rb`
- ERB exception handling formats correctly

---

## Part D: Integration and Refinement

### Task 2.10: Update Engine#visit with All Node Types

**Location:** `herb-format/lib/herb/format/engine.rb`

- [ ] Update visit() case statement to include all implemented node types
- [ ] Ensure every node type has a handler
- [ ] Add fallback for unknown node types (use IdentityPrinter)
- [ ] Update RBS type annotations

**Complete case statement:**
```ruby
def visit(node, depth:)
  case node.type
  # Document
  when :document then format_document(node, depth)

  # HTML
  when :html_element then format_element(node, depth)
  when :html_open_tag then format_open_tag(node, depth)
  when :html_close_tag then format_close_tag(node, depth)
  when :html_attribute then format_attribute(node, depth)
  when :html_attribute_name then format_attribute_name(node, depth)
  when :html_attribute_value then format_attribute_value(node, depth)
  when :html_text then format_text(node, depth)
  when :html_comment then format_comment(node, depth)
  when :html_doctype then format_doctype(node, depth)
  when :xml_declaration then format_xml_declaration(node, depth)
  when :cdata then format_cdata(node, depth)

  # Whitespace and literals
  when :whitespace then format_whitespace(node, depth)
  when :literal then format_literal(node, depth)

  # ERB
  when :erb_content then format_erb_content(node, depth)
  when :erb_yield then format_erb_yield(node, depth)
  when :erb_end then format_erb_end(node, depth)
  when :erb_block then format_erb_block(node, depth)
  when :erb_if then format_erb_if(node, depth)
  when :erb_else then format_erb_else(node, depth)
  when :erb_unless then format_erb_unless(node, depth)
  when :erb_case then format_erb_case(node, depth)
  when :erb_when then format_erb_when(node, depth)
  when :erb_while then format_erb_while(node, depth)
  when :erb_until then format_erb_until(node, depth)
  when :erb_for then format_erb_for(node, depth)
  when :erb_begin then format_erb_begin(node, depth)
  when :erb_rescue then format_erb_rescue(node, depth)
  when :erb_ensure then format_erb_ensure(node, depth)

  else
    # Fallback for unknown nodes
    @output << Herb::Printer::IdentityPrinter.print(node)
  end
end
```

**Verification:**
- All node types have handlers
- No missing node types

---

### Task 2.11: Wire Up Engine

**Location:** `herb-format/lib/herb/format.rb`

- [ ] Add require_relative for engine
- [ ] Run rbs-inline to generate signatures
- [ ] Run steep check

**Verification:**
- `cd herb-format && ./bin/steep check` passes
- Engine can be instantiated and used

---

### Task 2.12: Full Verification

- [ ] Run `cd herb-format && ./bin/rake` -- all checks pass
- [ ] Test Engine with various AST inputs
- [ ] Verify preserved elements (<pre>, <code>) are not reformatted
- [ ] Verify void elements have no close tag
- [ ] Verify ERB spacing is normalized
- [ ] Verify indentation is applied correctly

**Integration Test:**
```ruby
RSpec.describe Herb::Format::Engine do
  let(:engine) { described_class.new(indent_width: 2, max_line_length: 80) }
  let(:config) { build(:formatter_config, indent_width: 2, max_line_length: 80) }
  let(:context) { build(:context, config: config, source: source) }

  it "formats simple HTML" do
    source = "<div><p>Hello</p></div>"
    ast = Herb.parse(source).value

    formatted = engine.format(ast, context)

    expect(formatted).to eq(<<~HTML.chomp)
      <div>
        <p>
          Hello
        </p>
      </div>
    HTML
  end

  it "preserves <pre> content" do
    source = "<pre>  preserved  </pre>"
    ast = Herb.parse(source).value

    formatted = engine.format(ast, context)

    expect(formatted).to include("  preserved  ")
  end

  it "normalizes ERB tag spacing" do
    source = "<%=@user.name%>"
    ast = Herb.parse(source).value

    formatted = engine.format(ast, context)

    expect(formatted).to eq("<%= @user.name %>")
  end
end
```

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| 2.1 | A | Create Engine class foundation |
| 2.2 | B | Document and text formatting |
| 2.3 | B | Element formatting |
| 2.4 | B | Attribute formatting |
| 2.5 | B | Comment and special nodes |
| 2.6 | C | ERB content formatting |
| 2.7 | C | ERB block formatting |
| 2.8 | C | ERB control flow formatting |
| 2.9 | C | ERB exception handling |
| 2.10-2.12 | D | Integration and verification |

**Total: 12 tasks**

## Related Documents

- [herb-format Design](../design/herb-format-design.md)
- [herb-printer Design](../design/printer-design.md)
- [Phase 1: Foundation](./phase-1-formatter-foundation.md)
