# Phase 2: FormatPrinter (Final - TypeScript Analysis Based)

**Complete Task List - Based on Detailed Analysis of TypeScript Implementation**

This phase is a detailed, implementable task list based on complete understanding of the TypeScript `@herb-tools/formatter` FormatPrinter and format-helpers.

---

## 📚 Reference Documents

- **Formatting Rules:** [formatting-rules.md](../design/formatting-rules.md)
- **Design Document:** [herb-format-design.md](../design/herb-format-design.md)
- **TypeScript Repository:** https://github.com/marcoroth/herb

---

## 🎯 Phase 2 Goals

Implement TypeScript-compatible FormatPrinter to achieve:
- ✅ Smart inline vs block formatting decisions
- ✅ Attribute wrapping based on maxLineLength
- ✅ ERB tag normalization
- ✅ User-intentional whitespace preservation
- ✅ Content-preserving element protection

---

## 📊 Overall Structure

```
Part A: FormatHelpers Module (40+ functions)          ← Foundation
Part B: Core Patterns (capture, trackBoundary, etc.)  ← Infrastructure
Part C: ElementAnalyzer (inline/block decisions)      ← Analysis Engine
Part D: Attribute Formatting (wrapping logic)         ← Attributes
Part E: ERB Formatting (normalization, control flow)  ← ERB
Part F: Text Flow & Spacing (word wrapping, Rule 3)   ← Advanced
Part G: Integration & Testing                         ← Integration
```

**Estimated Total:** 25-30 tasks, 40-60 hours implementation time

---

## 📋 Task Checklist (Part 1)

### Part A: FormatHelpers Module (8 tasks)
- [x] Task 2.1: Constants Definition
- [x] Task 2.2: Basic Node Classification (6 functions)
- [x] Task 2.3: Sibling & Child Analysis (4 functions)
- [x] Task 2.4: Content Analysis (4 functions)
- [x] Task 2.5: Positioning & Spacing (2 functions)
- [x] Task 2.6: Text & Punctuation Helpers (5 functions)
- [ ] Task 2.7: ERB Helpers (3 functions)
- [ ] Task 2.8: Utility Functions (dedent, get_tag_name)

### Part B: Core Patterns (5 tasks)
- [ ] Task 2.9: State Management Fields
- [ ] Task 2.10: capture Pattern
- [ ] Task 2.11: trackBoundary Pattern
- [ ] Task 2.12: withIndent Pattern
- [ ] Task 2.13: Output Helper Methods

### Part C: ElementAnalyzer (4 tasks)
- [ ] Task 2.14: ElementAnalysis Data Structure
- [ ] Task 2.15: ElementAnalyzer - shouldRenderOpenTagInline
- [ ] Task 2.16: ElementAnalyzer - shouldRenderElementContentInline
- [ ] Task 2.17: ElementAnalyzer - Complete Implementation

### Part D: Attribute Formatting (4 tasks)
- [ ] Task 2.18: Attribute Inline Rendering
- [ ] Task 2.19: Attribute Multiline Rendering
- [ ] Task 2.20: Class Attribute Formatting
- [ ] Task 2.21: Quote Normalization

**Progress: 6/21 tasks completed**

---

## Part A: FormatHelpers Module

### Task 2.1: Constants Definition

**Purpose:** Port all constants from TypeScript's format-helpers.ts

**Location:** `herb-format/lib/herb/format/format_helpers.rb`

**Implementation Items:**
- [x] `INLINE_ELEMENTS` (Set[String]) - 26 elements
  ```ruby
  Set.new(%w[
    a abbr acronym b bdo big br cite code dfn em hr i img kbd label
    map object q samp small span strong sub sup tt var del ins mark s u time wbr
  ]).freeze
  ```

- [x] `CONTENT_PRESERVING_ELEMENTS` (Set[String]) - 4 elements
  ```ruby
  Set.new(%w[script style pre textarea]).freeze
  ```

- [x] `SPACEABLE_CONTAINERS` (Set[String]) - 12 elements
  ```ruby
  Set.new(%w[
    div section article main header footer aside figure
    details summary dialog fieldset
  ]).freeze
  ```

- [x] `TOKEN_LIST_ATTRIBUTES` (Set[String]) - 3 elements
  ```ruby
  Set.new(%w[class data-controller data-action]).freeze
  ```

- [x] `FORMATTABLE_ATTRIBUTES` (Hash[String, Array[String]])
  ```ruby
  {
    '*' => ['class'],
    'img' => ['srcset', 'sizes']
  }.freeze
  ```

- [x] `ASCII_WHITESPACE` (Regexp)
  ```ruby
  /[ \t\n\r]+/
  ```

**Test Cases:**
- All constants are frozen
- INLINE_ELEMENTS.include?('span') is true
- CONTENT_PRESERVING_ELEMENTS.include?('pre') is true
- TOKEN_LIST_ATTRIBUTES.include?('class') is true

**Estimate:** 30 minutes

**Dependencies:** None

---

### Task 2.2: Basic Node Classification (6 functions)

**Purpose:** Basic node classification functions

**Location:** `herb-format/lib/herb/format/format_helpers.rb`

**Implementation Items:**

- [x] 1. **pure_whitespace_node?(node)**
   ```ruby
   # @rbs node: Herb::AST::Node
   # @rbs return: bool
   def self.pure_whitespace_node?(node)
     node.is_a?(Herb::AST::HTMLTextNode) && node.content.strip.empty?
   end
   ```

- [x] 2. **non_whitespace_node?(node)**
   ```ruby
   def self.non_whitespace_node?(node)
     return false if node.is_a?(Herb::AST::WhitespaceNode)
     return node.content.strip != "" if node.is_a?(Herb::AST::HTMLTextNode)
     true
   end
   ```

- [x] 3. **inline_element?(tag_name)**
   ```ruby
   def self.inline_element?(tag_name)
     INLINE_ELEMENTS.include?(tag_name.downcase)
   end
   ```

- [x] 4. **content_preserving?(tag_name)**
   ```ruby
   def self.content_preserving?(tag_name)
     CONTENT_PRESERVING_ELEMENTS.include?(tag_name.downcase)
   end
   ```

- [x] 5. **block_level_node?(node)**
   ```ruby
   def self.block_level_node?(node)
     return false unless node.is_a?(Herb::AST::HTMLElementNode)
     tag_name = node.tag_name&.value || ""
     !inline_element?(tag_name)
   end
   ```

- [x] 6. **line_breaking_element?(node)**
   ```ruby
   def self.line_breaking_element?(node)
     return false unless node.is_a?(Herb::AST::HTMLElementNode)
     tag_name = node.tag_name&.value || ""
     %w[br hr].include?(tag_name.downcase)
   end
   ```

**Test Cases:**
- pure_whitespace_node? returns true for "   " text node
- non_whitespace_node? returns true for "text" text node
- inline_element?("span") is true
- block_level_node? returns true for div, false for span

**Estimate:** 1 hour

**Dependencies:** Task 2.1

---

### Task 2.3: Sibling & Child Analysis (4 functions)

**Purpose:** Analyze sibling and child nodes

**Location:** `herb-format/lib/herb/format/format_helpers.rb`

**Implementation Items:**

- [x] 1. **find_previous_meaningful_sibling(siblings, current_index)**
   - Returns index of previous meaningful sibling node
   - Skips whitespace

- [x] 2. **whitespace_between?(children, start_index, end_index)**
   - Check if whitespace exists between two indices

- [x] 3. **filter_significant_children(body)**
   - **Important:** Preserve single space ` `
   - Exclude empty text nodes
   - Exclude WhitespaceNode

- [x] 4. **count_adjacent_inline_elements(children)**
   - Count consecutive inline elements/ERB from start
   - Stop when interrupted by whitespace

**Test Cases:**
- find_previous_meaningful_sibling returns correct index
- filter_significant_children preserves ` `
- count_adjacent_inline_elements returns correct count

**Estimate:** 1.5 hours

**Dependencies:** Task 2.2

---

### Task 2.4: Content Analysis (4 functions)

**Purpose:** Analyze element content for inline decision

**Location:** `herb-format/lib/herb/format/format_helpers.rb`

**Implementation Items:**

1. **multiline_text_content?(children)**
   - Check if text nodes contain `\n`
   - Recursive check

2. **all_nested_elements_inline?(children)**
   - Check if all nested elements are inline
   - Recursive check
   - DOCTYPE, HTMLComment, ERB control flow return false

3. **mixed_text_and_inline_content?(children)**
   - Check if text and inline elements are mixed
   - Example: "Hello <em>world</em>!" → true

4. **complex_erb_control_flow?(children)**
   - Check if ERB if/unless spans multiple lines
   - location.start.line != location.end.line

**Test Cases:**
- multiline_text_content? returns true for "text\nmore"
- all_nested_elements_inline? returns true for all inline elements
- mixed_text_and_inline_content? returns true for mixed content

**Estimate:** 2 hours

**Dependencies:** Task 2.2

---

### Task 2.5: Positioning & Spacing (2 functions)

**Purpose:** Node positioning and spacing decisions

**Location:** `herb-format/lib/herb/format/format_helpers.rb`

**Implementation Items:**

1. **should_append_to_last_line?(child, siblings, index)**
   - Should append to previous line?
   - Text immediately after inline element
   - Adjacent inline elements
   - ERB on same line

2. **should_preserve_user_spacing?(child, siblings, index)**
   - Preserve user intentional spacing (\n\n)?
   - Meaningful nodes before and after

**Test Cases:**
- should_append_to_last_line? returns true for adjacent inline elements
- should_preserve_user_spacing? returns true for \n\n

**Estimate:** 1.5 hours

**Dependencies:** Task 2.2

---

### Task 2.6: Text & Punctuation Helpers (5 functions)

**Purpose:** Text flow and space detection

**Location:** `herb-format/lib/herb/format/format_helpers.rb`

**Implementation Items:**

1. **needs_space_between?(current_line, word)**
   - Does space needed between two words?
   - No space before closing punctuation: "text)"
   - No space after opening punctuation: "(text"
   - ERB + special symbols: "$<%= value %>"

2. **is_closing_punctuation?(word)**
   ```ruby
   word =~ /^[.,;:!?\)}\]]+$/
   ```

3. **is_opening_punctuation?(word)**
   ```ruby
   word =~ /[\(\[{]$/
   ```

4. **ends_with_erb_tag?(text)**
   ```ruby
   text =~ /%>$/
   ```

5. **starts_with_erb_tag?(text)**
   ```ruby
   text =~ /^<%/
   ```

**Test Cases:**
- needs_space_between?("Hello", "world") is true
- needs_space_between?("text", ")") is false
- needs_space_between?("$", "<%= value %>") is false

**Estimate:** 2 hours

**Dependencies:** None

---

### Task 2.7: ERB Helpers (3 functions)

**Purpose:** ERB node detection

**Location:** `herb-format/lib/herb/format/format_helpers.rb`

**Implementation Items:**

1. **erb_node?(node)**
   ```ruby
   def self.erb_node?(node)
     node.class.name.include?("ERB")
   end
   ```

2. **erb_control_flow_node?(node)**
   ```ruby
   def self.erb_control_flow_node?(node)
     node.is_a?(Herb::AST::ERBIfNode) ||
       node.is_a?(Herb::AST::ERBUnlessNode) ||
       node.is_a?(Herb::AST::ERBCaseNode) ||
       node.is_a?(Herb::AST::ERBBlockNode)
   end
   ```

3. **herb_disable_comment?(node)**
   ```ruby
   def self.herb_disable_comment?(node)
     return false unless node.is_a?(Herb::AST::ERBContentNode)
     return false unless node.tag_opening&.value == "<%#"

     content = node.content&.value || ""
     content.strip.start_with?("herb:disable")
   end
   ```

**Test Cases:**
- erb_node? returns true for ERBContentNode
- erb_control_flow_node? returns true for ERBIfNode
- herb_disable_comment? returns true for "<%# herb:disable %>"

**Estimate:** 1 hour

**Dependencies:** None

---

### Task 2.8: Utility Functions (dedent, get_tag_name)

**Purpose:** Utility functions

**Location:** `herb-format/lib/herb/format/format_helpers.rb`

**Implementation Items:**

1. **dedent(text)**
   ```ruby
   def self.dedent(text)
     lines = text.split("\n")
     min_indent = lines.reject { |line| line.strip.empty? }
                      .map { |line| line[/^\s*/].length }
                      .min || 0

     lines.map do |line|
       line.strip.empty? ? line : line[min_indent..-1]
     end.join("\n")
   end
   ```

2. **get_tag_name(element_node)**
   ```ruby
   def self.get_tag_name(element_node)
     element_node.tag_name&.value || ""
   end
   ```

**Test Cases:**
- dedent removes indentation correctly

**Estimate:** 30 minutes

**Dependencies:** None

---

**Part A Summary:**
- **Total Tasks:** 8 tasks
- **Function Count:** 30+
- **Estimate:** 10-12 hours
- **Difficulty:** Medium (straightforward implementation, testing is important)

---

## Part B: Core Patterns (FormatPrinter Foundation)

### Task 2.9: State Management Fields

**Purpose:** Add state management fields to FormatPrinter

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
class FormatPrinter < ::Herb::Printer::Base
  # Output management
  # @rbs @lines: Array[String]
  # @rbs @indent_level: Integer
  # @rbs @string_line_count: Integer

  # Context management
  # @rbs @inline_mode: bool
  # @rbs @in_conditional_open_tag_context: bool
  # @rbs @current_attribute_name: String?
  # @rbs @element_stack: Array[Herb::AST::HTMLElementNode]

  # Cache and analysis
  # @rbs @element_formatting_analysis: Hash[Herb::AST::HTMLElementNode, ElementAnalysis]
  # @rbs @node_is_multiline: Hash[Herb::AST::Node, bool]

  def initialize(...)
    super
    @lines = []
    @indent_level = 0
    @string_line_count = 0
    @inline_mode = false
    @in_conditional_open_tag_context = false
    @current_attribute_name = nil
    @element_stack = []
    @element_formatting_analysis = {}
    @node_is_multiline = {}
  end
end
```

**Test Cases:**
- All fields initialized correctly

**Estimate:** 30 minutes

**Dependencies:** None

---

### Task 2.10: capture Pattern

**Purpose:** Temporarily switch to separate output buffer

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Capture output to temporary buffer
#
# @rbs &block: () -> void
# @rbs return: Array[String]
def capture(&block)
  previous_lines = @lines
  previous_inline_mode = @inline_mode

  @lines = []

  yield

  result = @lines
  @lines = previous_lines
  @inline_mode = previous_inline_mode

  result
end
```

**Usage Example:**
```ruby
# Render entire element to determine length
rendered = capture { visit(node) }
total_length = rendered.join("").length

if total_length <= max_line_length
  # Output inline
else
  # Output block
end
```

**Test Cases:**
- Output inside capture block is returned as array
- @lines restored after capture

**Estimate:** 1 hour

**Dependencies:** Task 2.9

---

### Task 2.11: trackBoundary Pattern

**Purpose:** Record if node is multiline

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Track if a node spans multiple lines
#
# @rbs node: Herb::AST::Node
# @rbs &block: () -> void
# @rbs return: void
def track_boundary(node, &block)
  start_line_count = @string_line_count

  yield

  end_line_count = @string_line_count

  if end_line_count > start_line_count
    @node_is_multiline[node] = true
  end
end
```

**Usage Locations:**
- visitHTMLElementNode
- visitERBIfNode
- visitERBBlockNode

**Test Cases:**
- Multiline elements recorded correctly
- Single-line elements not recorded

**Estimate:** 1 hour

**Dependencies:** Task 2.9

---

### Task 2.12: withIndent Pattern

**Purpose:** Temporarily increase indent level

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Temporarily increase indent level
#
# @rbs &block: () -> void
# @rbs return: void
def with_indent(&block)
  @indent_level += 1
  yield
  @indent_level -= 1
end
```

**Usage Locations:**
- Formatting element body
- Inside ERB blocks
- Multiline attribute output

**Test Cases:**
- Indent increases inside block
- Indent restored after block

**Estimate:** 30 minutes

**Dependencies:** Task 2.9

---

### Task 2.13: Output Helper Methods

**Purpose:** Helper methods for output

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Current indent string
#
# @rbs return: String
def indent
  " " * (@indent_level * @indent_width)
end

# Push line with indentation
#
# @rbs line: String
# @rbs return: void
def push_with_indent(line)
  indent_str = line.strip.empty? ? "" : indent
  push(indent_str + line)
end

# Push to last line (no newline)
#
# @rbs text: String
# @rbs return: void
def push_to_last_line(text)
  if @lines.empty?
    @lines << text
  else
    @lines[-1] += text
  end
end

# Push line
#
# @rbs line: String
# @rbs return: void
def push(line)
  @lines << line
  @string_line_count += 1 if line.include?("\n")
end
```

**Test Cases:**
- indent returns correct number of spaces
- push_with_indent outputs with indentation
- push_to_last_line appends to last line

**Estimate:** 1 hour

**Dependencies:** Task 2.9

---

**Part B Summary:**
- **Total Tasks:** 5 tasks
- **Estimate:** 4-5 hours
- **Difficulty:** Medium (understanding patterns is important)

---

## Part C: ElementAnalyzer (Analysis Engine)

### Task 2.14: ElementAnalysis Data Structure

**Purpose:** Store element formatting decision results

**Location:** `herb-format/lib/herb/format/element_analysis.rb`

**Implementation Items:**

```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Analysis result for HTMLElementNode formatting decisions.
    #
    # @rbs open_tag_inline: bool
    # @rbs element_content_inline: bool
    # @rbs close_tag_inline: bool
    class ElementAnalysis < Data.define(:open_tag_inline, :element_content_inline, :close_tag_inline)
      # Element is fully inline (one line output)
      #
      # @rbs return: bool
      def fully_inline?
        open_tag_inline && element_content_inline && close_tag_inline
      end

      # Element uses block formatting
      #
      # @rbs return: bool
      def block_format?
        !element_content_inline
      end
    end
  end
end
```

**Test Cases:**
- fully_inline? works correctly
- block_format? works correctly

**Estimate:** 30 minutes

**Dependencies:** None

---

### Task 2.15: ElementAnalyzer - shouldRenderOpenTagInline

**Purpose:** Determine if open tag should be rendered inline

**Location:** `herb-format/lib/herb/format/element_analyzer.rb`

**Implementation Items:**

```ruby
# Should render open tag inline?
#
# @rbs element: Herb::AST::HTMLElementNode
# @rbs return: bool
def should_render_open_tag_inline?(element)
  # Conditional tag → false
  return false if @in_conditional_open_tag_context

  # Complex ERB → false
  inline_nodes = get_inline_nodes(element.open_tag)
  return false if FormatHelpers.complex_erb_control_flow?(inline_nodes)

  # Multiline attributes → false
  return false if has_multiline_attributes?(element.open_tag)

  # Check attribute count and line length
  should_render_inline?(element)
end

private

# Get inline nodes from open tag
#
# @rbs open_tag: Herb::AST::HTMLOpenTagNode
# @rbs return: Array[Herb::AST::Node]
def get_inline_nodes(open_tag)
  open_tag.child_nodes.reject do |child|
    child.is_a?(Herb::AST::WhitespaceNode) ||
      child.is_a?(Herb::AST::HTMLAttributeNode)
  end
end

# Has multiline attributes?
#
# @rbs open_tag: Herb::AST::HTMLOpenTagNode
# @rbs return: bool
def has_multiline_attributes?(open_tag)
  # TODO: Implementation (check if attribute values contain \n)
  false
end
```

**Test Cases:**
- Returns false for complex ERB
- Returns false for multiline attributes
- Correct decision for normal elements

**Estimate:** 2 hours

**Dependencies:** Task 2.14, Part A

---

### Task 2.16: ElementAnalyzer - shouldRenderElementContentInline

**Purpose:** Determine if element content should be rendered inline (most complex)

**Location:** `herb-format/lib/herb/format/element_analyzer.rb`

**Implementation Items:**

```ruby
# Should render element content inline?
#
# @rbs element: Herb::AST::HTMLElementNode
# @rbs open_tag_inline: bool
# @rbs return: bool
def should_render_element_content_inline?(element, open_tag_inline)
  # Open tag not inline → false
  return false unless open_tag_inline

  # No children → true
  return true if element.body.empty?

  # Has non-inline child → false
  has_non_inline_child = element.body.any? { |child| !inline_node?(child) }
  return false if has_non_inline_child

  tag_name = FormatHelpers.get_tag_name(element)

  # Inline element
  if FormatHelpers.inline_element?(tag_name)
    # Render entire element and check length
    rendered = @printer.capture { @printer.visit(element) }
    total_length = rendered.join("").length
    return total_length <= @max_line_length
  end

  # Block element
  significant_children = FormatHelpers.filter_significant_children(element.body)

  # Single text child
  if significant_children.length == 1 &&
     significant_children[0].is_a?(Herb::AST::HTMLTextNode)
    return !significant_children[0].content.include?("\n")
  end

  # All nested elements inline
  return true if FormatHelpers.all_nested_elements_inline?(significant_children)

  # Mixed text and inline
  return true if FormatHelpers.mixed_text_and_inline_content?(significant_children)

  false
end

private

# Is inline node?
#
# @rbs node: Herb::AST::Node
# @rbs return: bool
def inline_node?(node)
  return true if node.is_a?(Herb::AST::WhitespaceNode)
  return true if node.is_a?(Herb::AST::HTMLTextNode)

  if node.is_a?(Herb::AST::HTMLElementNode)
    tag_name = FormatHelpers.get_tag_name(node)
    return FormatHelpers.inline_element?(tag_name)
  end

  if FormatHelpers.erb_node?(node)
    return !FormatHelpers.erb_control_flow_node?(node)
  end

  false
end
```

**Test Cases:**
- Returns true for empty element
- Returns true for single text child
- Returns true for all inline
- Returns true for mixed text + inline
- Returns false for block element child

**Estimate:** 4 hours (most complex)

**Dependencies:** Task 2.15, Part A, Part B (capture)

---

### Task 2.17: ElementAnalyzer - Complete Implementation

**Purpose:** Complete ElementAnalyzer

**Location:** `herb-format/lib/herb/format/element_analyzer.rb`

**Implementation Items:**

```ruby
class ElementAnalyzer
  include FormatHelpers

  # @rbs @printer: FormatPrinter
  # @rbs @max_line_length: Integer
  # @rbs @indent_width: Integer
  # @rbs @in_conditional_open_tag_context: bool

  # @rbs printer: FormatPrinter
  # @rbs max_line_length: Integer
  # @rbs indent_width: Integer
  # @rbs return: void
  def initialize(printer, max_line_length, indent_width)
    @printer = printer
    @max_line_length = max_line_length
    @indent_width = indent_width
    @in_conditional_open_tag_context = false
  end

  # Analyze element and return formatting decisions
  #
  # @rbs element: Herb::AST::HTMLElementNode
  # @rbs return: ElementAnalysis
  def analyze(element)
    tag_name = FormatHelpers.get_tag_name(element)

    # Content-preserving → block
    if FormatHelpers.content_preserving?(tag_name)
      return ElementAnalysis.new(
        open_tag_inline: false,
        element_content_inline: false,
        close_tag_inline: false
      )
    end

    # Void element → inline
    if element.is_void
      return ElementAnalysis.new(
        open_tag_inline: true,
        element_content_inline: true,
        close_tag_inline: true
      )
    end

    # Analyze
    open_tag_inline = should_render_open_tag_inline?(element)
    element_content_inline = should_render_element_content_inline?(element, open_tag_inline)
    close_tag_inline = should_render_close_tag_inline?(element, element_content_inline)

    ElementAnalysis.new(
      open_tag_inline: open_tag_inline,
      element_content_inline: element_content_inline,
      close_tag_inline: close_tag_inline
    )
  end

  private

  # Should render close tag inline?
  #
  # @rbs element: Herb::AST::HTMLElementNode
  # @rbs element_content_inline: bool
  # @rbs return: bool
  def should_render_close_tag_inline?(element, element_content_inline)
    element_content_inline
  end

  # ... (Methods from Task 2.15, 2.16)
end
```

**Test Cases:**
- Correct analysis results for various element types

**Estimate:** 2 hours

**Dependencies:** Task 2.15, 2.16

---

**Part C Summary:**
- **Total Tasks:** 4 tasks
- **Estimate:** 8-10 hours
- **Difficulty:** Highest (most complex logic)

---

## Part D: Attribute Formatting

### Task 2.18: Attribute Inline Rendering

**Purpose:** Render attributes inline

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Render attributes inline (same line)
#
# @rbs open_tag: Herb::AST::HTMLOpenTagNode
# @rbs return: String
def render_attributes_inline(open_tag)
  attributes = open_tag.child_nodes.select { |child|
    child.is_a?(Herb::AST::HTMLAttributeNode)
  }

  return "" if attributes.empty?

  " " + attributes.map { |attr| render_attribute(attr) }.join(" ")
end

# Render single attribute
#
# @rbs attribute: Herb::AST::HTMLAttributeNode
# @rbs return: String
def render_attribute(attribute)
  name = get_attribute_name(attribute)
  @current_attribute_name = name

  if attribute.value.nil?
    # Boolean attribute
    @current_attribute_name = nil
    return name
  end

  # Process attribute value
  attribute_value = attribute.value
  open_quote, close_quote = get_attribute_quotes(attribute_value)

  content = render_attribute_value_content(attribute_value)

  @current_attribute_name = nil

  # Special handling for class attribute
  if name == "class"
    return render_class_attribute(name, content, open_quote, close_quote)
  end

  name + "=" + open_quote + content + close_quote
end
```

**Test Cases:**
- Boolean attributes rendered correctly
- Attribute values use double quotes
- Class attributes have special handling

**Estimate:** 2 hours

**Dependencies:** Part B

---

### Task 2.19: Attribute Multiline Rendering

**Purpose:** Render attributes in multiline format

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Render attributes in multiline format
#
# @rbs tag_name: String
# @rbs all_children: Array[Herb::AST::Node]
# @rbs is_void: bool
# @rbs return: void
def render_multiline_attributes(tag_name, all_children, is_void)
  # 1. Extract herb:disable comments
  herb_disable_comments = all_children.select do |child|
    FormatHelpers.herb_disable_comment?(child)
  end

  # 2. Opening line
  opening_line = "<#{tag_name}"

  if herb_disable_comments.any?
    comment_output = capture do
      herb_disable_comments.each do |comment|
        @inline_mode = true
        push(" ")
        visit(comment)
        @inline_mode = false
      end
    end
    opening_line += comment_output.join("")
  end

  push_with_indent(opening_line)

  # 3. Output each attribute with indentation
  with_indent do
    all_children.each do |child|
      if child.is_a?(Herb::AST::HTMLAttributeNode)
        push_with_indent(render_attribute(child))
      elsif !child.is_a?(Herb::AST::WhitespaceNode)
        unless FormatHelpers.herb_disable_comment?(child)
          visit(child)
        end
      end
    end
  end

  # 4. Closing tag
  push_with_indent(is_void ? "/>" : ">")
end
```

**Test Cases:**
- Attributes output one per line
- Indentation is correct
- herb:disable comments are processed

**Estimate:** 2 hours

**Dependencies:** Task 2.18

---

### Task 2.20: Class Attribute Formatting

**Purpose:** Special handling for class attribute (wrapping for long values)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Format class attribute with potential wrapping
#
# @rbs name: String
# @rbs content: String
# @rbs open_quote: String
# @rbs close_quote: String
# @rbs return: String
def format_class_attribute(name, content, open_quote, close_quote)
  # Normalize spaces
  normalized_content = content.gsub(/[ \t\n\r]+/, ' ').strip

  # Has actual newlines and is long
  has_actual_newlines = content.include?("\n")

  if has_actual_newlines && normalized_content.length > 80
    lines = content.split(/\r?\n/).map(&:strip).reject(&:empty?)

    if lines.length > 1
      return name + "=" + open_quote +
             format_multiline_attribute_value(lines) +
             close_quote
    end
  end

  # Line length check
  current_indent = @indent_level * @indent_width
  attribute_line = "#{name}=#{open_quote}#{normalized_content}#{close_quote}"

  if current_indent + attribute_line.length > @max_line_length &&
     normalized_content.length > 60
    # If ERB included, normalize only
    if normalized_content.include?("<%")
      return name + "=" + open_quote + normalized_content + close_quote
    end

    # Split classes and wrap
    classes = normalized_content.split(' ')
    lines = break_tokens_into_lines(classes, current_indent)

    if lines.length > 1
      return name + "=" + open_quote +
             format_multiline_attribute_value(lines) +
             close_quote
    end
  end

  name + "=" + open_quote + normalized_content + close_quote
end

private

# Break tokens into lines based on max_line_length
#
# @rbs tokens: Array[String]
# @rbs indent: Integer
# @rbs return: Array[String]
def break_tokens_into_lines(tokens, indent)
  lines = []
  current_line = []
  current_length = indent

  tokens.each do |token|
    test_length = current_length + token.length + 1

    if test_length > @max_line_length && current_line.any?
      lines << current_line.join(' ')
      current_line = [token]
      current_length = indent + token.length
    else
      current_line << token
      current_length = test_length
    end
  end

  lines << current_line.join(' ') if current_line.any?

  lines
end

# Format multiline attribute value
#
# @rbs lines: Array[String]
# @rbs return: String
def format_multiline_attribute_value(lines)
  "\n" + lines.map { |line| "  " + line }.join("\n") + "\n"
end
```

**Test Cases:**
- Long class wraps
- Class with ERB only normalizes
- Short class stays as-is

**Estimate:** 3 hours

**Dependencies:** Task 2.18

---

### Task 2.21: Quote Normalization

**Purpose:** Normalize attribute value quotes (single → double)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Get attribute quotes (normalize to double)
#
# @rbs attribute_value: Herb::AST::HTMLAttributeValueNode
# @rbs return: [String, String]
def get_attribute_quotes(attribute_value)
  open_quote = attribute_value.open_quote&.value || ""
  close_quote = attribute_value.close_quote&.value || ""

  # No quotes → double quotes
  if open_quote.empty? && close_quote.empty?
    return ['"', '"']
  end

  # Single quotes → double quotes (if possible)
  if open_quote == "'" && close_quote == "'"
    html_text_content = get_html_text_content(attribute_value)

    unless html_text_content.include?('"')
      return ['"', '"']
    end
  end

  [open_quote, close_quote]
end

# Get HTML text content from attribute value
#
# @rbs attribute_value: Herb::AST::HTMLAttributeValueNode
# @rbs return: String
def get_html_text_content(attribute_value)
  attribute_value.children.filter_map do |child|
    if child.is_a?(Herb::AST::HTMLTextNode) ||
       child.is_a?(Herb::AST::LiteralNode)
      child.content
    end
  end.join("")
end
```

**Test Cases:**
- Single quotes converted to double
- Double quotes preserved when content has double quotes

**Estimate:** 1 hour

**Dependencies:** Task 2.18

---

**Part D Summary:**
- **Total Tasks:** 4 tasks
- **Estimate:** 8-10 hours
- **Difficulty:** High (class attribute wrapping is complex)

---

## Continued in Part 2...

This document is long, so Part E (ERB Formatting), Part F (Text Flow & Spacing), and Part G (Integration) are in [phase-2.2.md](./phase-2.2.md).

**Current Progress:**
- Part A: FormatHelpers (8 tasks, 10-12h)
- Part B: Core Patterns (5 tasks, 4-5h)
- Part C: ElementAnalyzer (4 tasks, 8-10h)
- Part D: Attribute Formatting (4 tasks, 8-10h)

**Total (Part A-D):** 21 tasks, 30-37 hours

**Remaining:**
- Part E: ERB Formatting (6-8 tasks, 10-15h)
- Part F: Text Flow & Spacing (4-6 tasks, 8-12h)
- Part G: Integration (3-4 tasks, 4-6h)

**Overall Estimate:** 34-41 tasks, 52-70 hours

---

## Next Steps

1. **Detail Part E-G** - ERB, Text Flow, Spacing, Integration
2. **Create Dependency Graph** - Identify critical path
3. **Optimize Implementation Order** - Start with parts that can be tested early

**Create continuation?**
