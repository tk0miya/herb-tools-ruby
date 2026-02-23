# Phase 2: FormatPrinter (Final - Part 2)

**Part E-G: ERB Formatting, Text Flow & Spacing, Integration**

This document is a continuation of [phase-2.1.md](./phase-2.1.md).

---

## 📋 Task Checklist (Part 2)

### Part E: ERB Formatting (7 tasks)
- [x] Task 2.22: ERB Tag Normalization (formatERBContent, reconstructERBNode)
- [x] Task 2.23: ERB Content Node (visitERBContentNode)
- [x] Task 2.24: ERB If Node (visitERBIfNode) - Inline Mode
- [x] Task 2.25: ERB If Node - Block Mode
- [x] Task 2.26: ERB Block Node (visitERBBlockNode)
- [ ] Task 2.27: ERB Other Control Flow (unless, case, for, while)
- [ ] Task 2.28: ERB Comment Node (visitERBCommentNode)
- [ ] Task 2.28b: Pending Tests for render_multiline_attributes (ERB nodes in attributes)

### Part F: Text Flow & Spacing (6 tasks)
- [x] Task 2.29: ContentUnit Data Structure
- [ ] Task 2.30: buildContentUnitsWithNodes
- [ ] Task 2.31: buildAndWrapTextFlow
- [ ] Task 2.32: flushWords (Word Wrapping)
- [ ] Task 2.33: Spacing Logic ("Rule of Three")
- [ ] Task 2.34: visitTextFlowChildren & visitElementChildren

### Part G: Integration & Testing (5 tasks)
- [ ] Task 2.35: Wire Up All Components
- [x] Task 2.35b: Migrate write-based visitors to push (output unification)
- [ ] Task 2.35c: Migrate visit_erb_if_node tests to use `.format` as entry point
- [ ] Task 2.36: Integration Tests
- [ ] Task 2.37: TypeScript Output Comparison
- [ ] Task 2.38: Performance & Edge Cases
- [ ] Task 2.39: Full Verification

**Progress: 6/19 tasks completed**

---

## Part E: ERB Formatting

### Task 2.22: ERB Tag Normalization (formatERBContent, reconstructERBNode)

**Purpose:** Normalize ERB tags (add spaces)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Format ERB content (add spaces)
#
# @rbs content: String
# @rbs return: String
def format_erb_content(content)
  trimmed_content = content.strip

  # Heredoc support (TypeScript issue #476)
  suffix = trimmed_content.start_with?("<<") ? "\n" : " "

  trimmed_content.empty? ? "" : " #{trimmed_content}#{suffix}"
end

# Reconstruct ERB node as string
#
# @rbs node: Herb::AST::ERBContentNode
# @rbs with_formatting: bool
# @rbs return: String
def reconstruct_erb_node(node, with_formatting: true)
  open = node.tag_opening&.value || ""
  close = node.tag_closing&.value || ""
  content = node.content&.value || ""

  inner = with_formatting ? format_erb_content(content) : content

  open + inner + close
end

# Print ERB node with indent
#
# @rbs node: Herb::AST::ERBContentNode
# @rbs return: void
def print_erb_node(node)
  indent_str = @inline_mode ? "" : indent
  erb_text = reconstruct_erb_node(node, with_formatting: true)

  push(indent_str + erb_text)
end
```

**Normalization Rules:**
- `<%=content%>` → `<%= content %>`
- `<%  spaced  %>` → `<%= spaced %>`
- `<%=<<HEREDOC%>` → `<%= <<HEREDOC\n%>` (heredoc)

**Test Cases:**
- ERB tags are normalized
- Heredocs are handled correctly

**Estimate:** 2 hours

**Dependencies:** Part B

---

### Task 2.23: ERB Content Node (visitERBContentNode)

**Purpose:** Output simple ERB tags (`<%= %>`, `<% %>`)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Visit ERB content node
#
# @rbs override
# @rbs node: Herb::AST::ERBContentNode
# @rbs return: void
def visit_erb_content_node(node)
  # Handle comments separately
  if node.tag_opening&.value == "<%#"
    visit_erb_comment_node(node)
    return
  end

  print_erb_node(node)
end
```

**Test Cases:**
- `<%=@user.name%>` normalized to `<%= @user.name %>`
- Indentation is correct

**Note:** Add integration tests via `.format` here. Fill in the `"with ERB tags"` context in `format_printer_spec.rb` (currently pending) with tests that verify actual formatted output flowing through `format_erb_content` → `reconstruct_erb_node` → `print_erb_node`. At the same time, remove the unit tests for `#format_erb_content`, `#reconstruct_erb_node`, and `#print_erb_node` that were added in Task 2.22, as they will be fully covered by the integration tests.

**Estimate:** 30 minutes

**Dependencies:** Task 2.22

---

### Task 2.24: ERB If Node (visitERBIfNode) - Inline Mode

**Purpose:** Handle ERB if nodes (most complex) - inline mode (inside attributes)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Visit ERB if node
#
# @rbs override
# @rbs node: Herb::AST::ERBIfNode
# @rbs return: void
def visit_erb_if_node(node)
  track_boundary(node) do
    if @inline_mode
      visit_erb_if_inline(node)
    else
      visit_erb_if_block(node)
    end
  end
end

private

# Visit ERB if in inline mode (inside attributes)
#
# @rbs node: Herb::AST::ERBIfNode
# @rbs return: void
def visit_erb_if_inline(node)
  print_erb_node(node)

  node.statements.each do |child|
    if child.is_a?(Herb::AST::HTMLAttributeNode)
      push(" ")
      push(render_attribute(child))
    else
      should_add_spaces = in_token_list_attribute?

      push(" ") if should_add_spaces

      visit(child)

      push(" ") if should_add_spaces
    end
  end

  # Add space for token list attributes
  has_html_attributes = node.statements.any? { |child|
    child.is_a?(Herb::AST::HTMLAttributeNode)
  }
  is_token_list = in_token_list_attribute?

  if (has_html_attributes || is_token_list) && node.end_node
    push(" ")
  end

  visit(node.subsequent) if node.subsequent
  visit(node.end_node) if node.end_node
end

# Check if currently in token list attribute
#
# @rbs return: bool
def in_token_list_attribute?
  @current_attribute_name &&
    FormatHelpers::TOKEN_LIST_ATTRIBUTES.include?(@current_attribute_name)
end
```

**Example (Inline Mode - Inside Attributes):**
```erb
<!-- Input -->
<div <% if disabled%>class="disabled"<%end%>>

<!-- Output -->
<div
  <% if disabled %>
    class="disabled"
  <% end %>
>
```

**Example (Token List Attribute):**
```erb
<!-- Input -->
<div class="btn<%if active%>active<%end%>">

<!-- Output -->
<div class="btn <% if active %> active <% end %>">
```

**Test Cases:**
- ERB if inside attributes handled correctly
- Spaces added in token list attributes

**Estimate:** 3 hours

**Dependencies:** Task 2.22

---

### Task 2.25: ERB If Node - Block Mode

**Purpose:** Handle ERB if nodes - block mode (normal)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Visit ERB if in block mode
#
# @rbs node: Herb::AST::ERBIfNode
# @rbs return: void
def visit_erb_if_block(node)
  print_erb_node(node)

  with_indent do
    node.statements.each { |child| visit(child) }
  end

  visit(node.subsequent) if node.subsequent
  visit(node.end_node) if node.end_node
end
```

**Example (Block Mode):**
```erb
<!-- Input -->
<% if user.admin? %><%= link_to "Admin", admin_path %><% end %>

<!-- Output -->
<% if user.admin? %>
  <%= link_to "Admin", admin_path %>
<% end %>
```

**Test Cases:**
- ERB if block indentation
- Nested ERB if

**Estimate:** 2 hours

**Dependencies:** Task 2.24

---

### Task 2.26: ERB Block Node (visitERBBlockNode)

**Purpose:** Handle ERB blocks (each, map, etc.)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Visit ERB block node (each, map, etc.)
#
# @rbs override
# @rbs node: Herb::AST::ERBBlockNode
# @rbs return: void
def visit_erb_block_node(node)
  track_boundary(node) do
    print_erb_node(node)

    with_indent do
      has_text_flow = is_in_text_flow_context?(nil, node.body)

      if has_text_flow
        visit_text_flow_children(node.body)
      else
        visit_element_children(node.body, nil)
      end
    end

    visit(node.end_node) if node.end_node
  end
end

private

# Is in text flow context?
#
# @rbs parent: Herb::AST::Node?
# @rbs children: Array[Herb::AST::Node]
# @rbs return: bool
def is_in_text_flow_context?(parent, children)
  has_text_content = children.any? do |child|
    child.is_a?(Herb::AST::HTMLTextNode) && !child.content.strip.empty?
  end

  non_text_children = children.reject { |child|
    child.is_a?(Herb::AST::HTMLTextNode)
  }

  return false unless has_text_content
  return false if non_text_children.empty?

  all_inline = non_text_children.all? do |child|
    next true if child.is_a?(Herb::AST::ERBContentNode)

    if child.is_a?(Herb::AST::HTMLElementNode)
      tag_name = FormatHelpers.get_tag_name(child)
      FormatHelpers.inline_element?(tag_name)
    else
      false
    end
  end

  all_inline
end
```

**Text Flow Detection:**
- Text content exists
- Non-text child elements exist
- All are inline elements or ERB

**Example (Block):**
```erb
<ul>
  <% users.each do |user| %>
    <li><%= user.name %></li>
  <% end %>
</ul>
```

**Example (Text Flow):**
```erb
<p>
  <% users.each do |user| %>
    <%= user.name %>
  <% end %>
</p>
```

**Test Cases:**
- ERB each block indentation
- Text flow detection

**Estimate:** 3 hours

**Dependencies:** Task 2.22, Part F (text flow)

---

### Task 2.27: ERB Other Control Flow (unless, case, for, while)

**Purpose:** Other ERB control flow

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Visit ERB unless node
#
# @rbs override
# @rbs node: Herb::AST::ERBUnlessNode
# @rbs return: void
def visit_erb_unless_node(node)
  track_boundary(node) do
    print_erb_node(node)

    with_indent do
      node.statements.each { |child| visit(child) }
    end

    visit(node.else_clause) if node.else_clause
    visit(node.end_node) if node.end_node
  end
end

# Visit ERB else node
#
# @rbs override
# @rbs node: Herb::AST::ERBElseNode
# @rbs return: void
def visit_erb_else_node(node)
  print_erb_node(node)

  if @inline_mode
    node.statements.each { |child| visit(child) }
  else
    with_indent do
      node.statements.each { |child| visit(child) }
    end
  end
end

# Visit ERB case node
#
# @rbs override
# @rbs node: Herb::AST::ERBCaseNode
# @rbs return: void
def visit_erb_case_node(node)
  track_boundary(node) do
    print_erb_node(node)

    with_indent do
      node.children.each { |child| visit(child) }
    end

    node.conditions.each { |cond| visit(cond) }

    visit(node.else_clause) if node.else_clause
    visit(node.end_node) if node.end_node
  end
end

# Visit ERB for, while, until (same pattern)
#
# @rbs override
def visit_erb_for_node(node)
  track_boundary(node) do
    print_erb_node(node)

    with_indent do
      node.statements.each { |child| visit(child) }
    end

    visit(node.end_node) if node.end_node
  end
end

# while, until also use same pattern
alias_method :visit_erb_while_node, :visit_erb_for_node
alias_method :visit_erb_until_node, :visit_erb_for_node
```

**Test Cases:**
- unless, case, for, while, until indentation

**Estimate:** 2 hours

**Dependencies:** Task 2.22

---

### Task 2.28: ERB Comment Node (visitERBCommentNode)

**Purpose:** Handle ERB comments (single/multi-line)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Visit ERB comment node
#
# @rbs node: Herb::AST::ERBContentNode
# @rbs return: void
def visit_erb_comment_node(node)
  open = node.tag_opening&.value || "<%#"
  content = node.content&.value || ""
  close = node.tag_closing&.value || "%>"

  content_lines = content.split("\n")
  content_trimmed_lines = content.trim.split("\n")

  # Single-line comment
  if content_lines.length == 1 && content_trimmed_lines.length == 1
    starts_with_space = content[0] == " "
    before = starts_with_space ? "" : " "

    if @inline_mode
      push(open + before + content.rstrip + " " + close)
    else
      push_with_indent(open + before + content.rstrip + " " + close)
    end

    return
  end

  # Multi-line but single trimmed line
  if content_trimmed_lines.length == 1
    if @inline_mode
      push(open + " " + content.strip + " " + close)
    else
      push_with_indent(open + " " + content.strip + " " + close)
    end

    return
  end

  # Multi-line comment
  first_line_empty = content_lines[0].strip.empty?
  dedented_content = FormatHelpers.dedent(
    first_line_empty ? content : content.lstrip
  )

  push_with_indent(open)

  with_indent do
    dedented_content.split("\n").each do |line|
      push_with_indent(line)
    end
  end

  push_with_indent(close)
end
```

**Example:**
```erb
<!-- Single line -->
<%#Comment%>
↓
<%# Comment %>

<!-- Multi-line -->
<%# hello
  multi-line
  comment
%>
↓
<%#
  hello
  multi-line
  comment
%>
```

**Test Cases:**
- Single-line comments normalized
- Multi-line comments indented

**Estimate:** 2 hours

**Dependencies:** Task 2.22, Task 2.8 (dedent)

---

### Task 2.28b: Pending Tests for render_multiline_attributes (ERB nodes in attributes)

**Purpose:** Implement the four pending test contexts in `describe "#render_multiline_attributes"`
that were deferred until ERB comment node support is available.

**Location:** `herb-format/spec/herb/format/format_printer_spec.rb`

**Test Cases to Implement:**

- "with herb:disable comment in open tag" — verifies that the herb:disable comment is appended
  inline to the opening line (expected output depends on `visit_erb_comment_node` in Task 2.28)
- "with ERB tag in attribute value" — verifies the `visit(child)` branch for non-attribute,
  non-whitespace, non-herb:disable children (e.g. `<div <%= dynamic_attr %>></div>`)
- "with multiple herb:disable comments" — verifies that `herb_disable_comments.each` iterates
  all comments and appends them all to the opening line
- "with herb:disable comment and no other attributes" — verifies correct output with no attribute lines

Remove the `pending` placeholder and replace each context with a `subject` and concrete `it` block.

**Estimate:** 30 minutes

**Dependencies:** Task 2.28

---

**Part E Summary:**
- **Total Tasks:** 8 tasks (2.22–2.28b)
- **Estimate:** 14-17 hours
- **Difficulty:** High (ERB if inline mode is most complex)

---

## Part F: Text Flow & Spacing

### Task 2.29: ContentUnit Data Structure

**Purpose:** Content unit for text flow

**Location:** `herb-format/lib/herb/format/content_unit.rb`

**Implementation Items:**

```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Content unit for text flow analysis
    #
    # @rbs content: String
    # @rbs type: Symbol
    # @rbs is_atomic: bool
    # @rbs breaks_flow: bool
    # @rbs is_herb_disable: bool
    class ContentUnit < Data.define(
      :content,
      :type,
      :is_atomic,
      :breaks_flow,
      :is_herb_disable
    )
      # @rbs content: String
      # @rbs type: Symbol
      # @rbs is_atomic: bool
      # @rbs breaks_flow: bool
      # @rbs is_herb_disable: bool
      # @rbs return: void
      def initialize(
        content:,
        type: :text,
        is_atomic: false,
        breaks_flow: false,
        is_herb_disable: false
      )
        super(
          content: content,
          type: type,
          is_atomic: is_atomic,
          breaks_flow: breaks_flow,
          is_herb_disable: is_herb_disable
        )
      end
    end

    # Content unit with associated node
    #
    # @rbs unit: ContentUnit
    # @rbs node: Herb::AST::Node?
    class ContentUnitWithNode < Data.define(:unit, :node)
    end
  end
end
```

**ContentUnit types:**
- `:text` - Text (splittable)
- `:inline` - Inline element (atomic)
- `:erb` - ERB (atomic)
- `:block` - Block element (breaks flow)

**Estimate:** 30 minutes

**Dependencies:** None

---

### Task 2.30: buildContentUnitsWithNodes

**Purpose:** Convert child nodes to content units

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Build content units from children
#
# @rbs children: Array[Herb::AST::Node]
# @rbs return: Array[ContentUnitWithNode]
def build_content_units_with_nodes(children)
  result = []
  last_processed_index = -1

  children.each_with_index do |child, index|
    next if index <= last_processed_index

    if child.is_a?(Herb::AST::HTMLTextNode)
      # Text node
      result << ContentUnitWithNode.new(
        unit: ContentUnit.new(
          content: child.content,
          type: :text,
          is_atomic: false,
          breaks_flow: false
        ),
        node: child
      )
    elsif child.is_a?(Herb::AST::ERBContentNode)
      # ERB node
      process_erb_content_node(result, children, child, index, last_processed_index)
    elsif child.is_a?(Herb::AST::HTMLElementNode)
      # Element node
      tag_name = FormatHelpers.get_tag_name(child)

      if FormatHelpers.inline_element?(tag_name)
        # Inline element → atomic
        rendered = capture { visit(child) }
        result << ContentUnitWithNode.new(
          unit: ContentUnit.new(
            content: rendered.join(""),
            type: :inline,
            is_atomic: true,
            breaks_flow: false
          ),
          node: child
        )
      else
        # Block element → breaks flow
        result << ContentUnitWithNode.new(
          unit: ContentUnit.new(
            content: "",
            type: :block,
            is_atomic: true,
            breaks_flow: true
          ),
          node: child
        )
      end
    else
      # Other (WhitespaceNode, etc.) → skip
    end
  end

  result
end

private

# Process ERB content node
#
# @rbs result: Array[ContentUnitWithNode]
# @rbs children: Array[Herb::AST::Node]
# @rbs child: Herb::AST::ERBContentNode
# @rbs index: Integer
# @rbs last_processed_index: Integer
# @rbs return: bool
def process_erb_content_node(result, children, child, index, last_processed_index)
  erb_content = render_erb_as_string(child)
  is_herb_disable = FormatHelpers.herb_disable_comment?(child)

  result << ContentUnitWithNode.new(
    unit: ContentUnit.new(
      content: erb_content,
      type: :erb,
      is_atomic: true,
      breaks_flow: false,
      is_herb_disable: is_herb_disable
    ),
    node: child
  )

  false
end

# Render ERB as string
#
# @rbs node: Herb::AST::ERBContentNode
# @rbs return: String
def render_erb_as_string(node)
  reconstruct_erb_node(node, with_formatting: true)
end
```

**Test Cases:**
- Text nodes become :text units
- ERB becomes :erb atomic units
- Inline elements become :inline atomic units
- Block elements become :block (breaks_flow)

**Estimate:** 2 hours

**Dependencies:** Task 2.29, Part E (ERB)

---

### Task 2.31: buildAndWrapTextFlow

**Purpose:** Build and wrap text flow

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Build and wrap text flow
#
# @rbs children: Array[Herb::AST::Node]
# @rbs return: void
def build_and_wrap_text_flow(children)
  units_with_nodes = build_content_units_with_nodes(children)
  words = []

  units_with_nodes.each do |unit_with_node|
    unit = unit_with_node.unit
    node = unit_with_node.node

    if unit.breaks_flow
      # Breaks flow → flush then output element
      flush_words(words)
      visit(node) if node
    elsif unit.is_atomic
      # Atomic unit → add as-is
      words << { word: unit.content, is_herb_disable: unit.is_herb_disable }
    else
      # Text → process spaces and split into words
      process_text_unit(words, unit.content)
    end
  end

  flush_words(words)
end

private

# Process text unit (split into words)
#
# @rbs words: Array[Hash]
# @rbs text: String
# @rbs return: void
def process_text_unit(words, text)
  # Normalize ASCII_WHITESPACE to single space
  normalized_text = text.gsub(FormatHelpers::ASCII_WHITESPACE, ' ')

  has_leading_space = normalized_text.start_with?(' ')
  has_trailing_space = normalized_text.end_with?(' ')
  trimmed_text = normalized_text.strip

  return if trimmed_text.empty? && normalized_text != ' '

  # Leading space processing
  if has_leading_space && words.any?
    last_word = words.last
    last_word[:word] += ' ' unless last_word[:word].end_with?(' ')
  end

  # Add words
  if trimmed_text.empty?
    # Single space
    if words.any?
      words.last[:word] += ' ' unless words.last[:word].end_with?(' ')
    end
  else
    text_words = trimmed_text.split(' ').map { |w| { word: w, is_herb_disable: false } }
    words.concat(text_words)
  end

  # Trailing space processing
  if has_trailing_space && words.any?
    last_word = words.last
    unless FormatHelpers.is_closing_punctuation?(last_word[:word])
      last_word[:word] += ' '
    end
  end
end
```

**Test Cases:**
- Text split into words
- Spaces processed correctly
- Atomic units preserved as-is

**Estimate:** 3 hours

**Dependencies:** Task 2.30

---

### Task 2.32: flushWords (Word Wrapping)

**Purpose:** Word wrapping logic

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Flush words to output with wrapping
#
# @rbs words: Array[Hash]
# @rbs return: void
def flush_words(words)
  return if words.empty?

  wrap_width = @max_line_length - indent.length
  current_line = ""

  words.each do |word_hash|
    word = word_hash[:word]
    is_herb_disable = word_hash[:is_herb_disable]

    if current_line.empty?
      # First word
      current_line = word
    else
      # Check if space needed
      needs_space = FormatHelpers.needs_space_between?(current_line, word)
      test_line = current_line + (needs_space ? " " : "") + word

      if test_line.length > wrap_width && !is_herb_disable
        # Wrap
        push_with_indent(current_line)
        current_line = word
      else
        current_line = test_line
      end
    end
  end

  push_with_indent(current_line) if !current_line.empty?

  words.clear
end
```

**Wrapping Logic:**
1. If current line empty, add word
2. Use `needs_space_between?` for space detection
3. If test line exceeds `wrap_width`, wrap
4. If `is_herb_disable`, don't wrap

**Test Cases:**
- Long text wraps
- ERB placed correctly
- herb:disable not wrapped

**Estimate:** 2 hours

**Dependencies:** Task 2.31, Task 2.6 (needs_space_between)

---

### Task 2.33: Spacing Logic ("Rule of Three")

**Purpose:** Spacing decisions between siblings

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Should add spacing between siblings?
#
# @rbs parent_element: Herb::AST::HTMLElementNode?
# @rbs siblings: Array[Herb::AST::Node]
# @rbs current_index: Integer
# @rbs return: bool
def should_add_spacing_between_siblings?(parent_element, siblings, current_index)
  current_node = siblings[current_index]
  previous_meaningful_index = FormatHelpers.find_previous_meaningful_sibling(siblings, current_index)
  previous_node = previous_meaningful_index != -1 ? siblings[previous_meaningful_index] : nil

  return false unless previous_node

  # 1. Always add spacing after XML declaration or DOCTYPE
  if previous_node.is_a?(Herb::AST::XMLDeclarationNode) ||
     previous_node.is_a?(Herb::AST::HTMLDoctypeNode)
    return true
  end

  # 2. No spacing if mixed text content
  has_mixed_content = siblings.any? do |child|
    child.is_a?(Herb::AST::HTMLTextNode) && !child.content.strip.empty?
  end
  return false if has_mixed_content

  # 3. Comment handling
  is_current_comment = is_comment_node?(current_node)
  is_previous_comment = is_comment_node?(previous_node)
  is_current_multiline = is_multiline_element?(current_node)
  is_previous_multiline = is_multiline_element?(previous_node)

  if is_previous_comment && !is_current_comment &&
     (current_node.is_a?(Herb::AST::HTMLElementNode) || FormatHelpers.erb_node?(current_node))
    return is_previous_multiline && is_current_multiline
  end

  return false if is_previous_comment && is_current_comment

  # 4. Always add spacing after multiline element
  return true if is_current_multiline || is_previous_multiline

  # 5-10. Tag groups, SPACEABLE_CONTAINERS, etc.
  # (Simplified: implement multiline detection only for now)

  false
end

private

# Is comment node?
#
# @rbs node: Herb::AST::Node
# @rbs return: bool
def is_comment_node?(node)
  node.is_a?(Herb::AST::HTMLCommentNode) ||
    (node.is_a?(Herb::AST::ERBContentNode) && node.tag_opening&.value == "<%#")
end

# Is multiline element?
#
# @rbs node: Herb::AST::Node
# @rbs return: bool
def is_multiline_element?(node)
  @node_is_multiline[node] || false
end
```

**Full "Rule of Three" implementation is complex, implement incrementally:**
1. Basic multiline detection first
2. Add tag group detection later

**Test Cases:**
- Spacing after multiline element
- Spacing after DOCTYPE
- No spacing for mixed text

**Estimate:** 4 hours (6-8 hours for full implementation)

**Dependencies:** Task 2.11 (trackBoundary)

---

### Task 2.34: visitTextFlowChildren & visitElementChildren

**Purpose:** Visit children (text flow vs normal)

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

```ruby
# Visit children in text flow mode
#
# @rbs children: Array[Herb::AST::Node]
# @rbs return: void
def visit_text_flow_children(children)
  build_and_wrap_text_flow(children)
end

# Visit children as elements (block mode)
#
# @rbs children: Array[Herb::AST::Node]
# @rbs parent: Herb::AST::HTMLElementNode?
# @rbs return: void
def visit_element_children(children, parent)
  children.each_with_index do |child, index|
    # Spacing decision
    if should_add_spacing_between_siblings?(parent, children, index)
      push("")  # Add blank line
    end

    # Whitespace handling
    if FormatHelpers.pure_whitespace_node?(child)
      if FormatHelpers.should_preserve_user_spacing?(child, children, index)
        push("")  # Preserve user intentional blank line
      end
      next
    end

    # Visit child node
    visit(child)
  end
end
```

**Test Cases:**
- Text flow wraps correctly
- Element spacing is correct
- User blank lines preserved

**Estimate:** 2 hours

**Dependencies:** Task 2.31, Task 2.33

---

**Part F Summary:**
- **Total Tasks:** 6 tasks
- **Estimate:** 13-15 hours
- **Difficulty:** Highest (text flow + spacing logic)

---

## Part G: Integration & Testing

### Task 2.35: Wire Up All Components

**Purpose:** Integrate all components

**Location:** `herb-format/lib/herb/format.rb`

**Implementation Items:**

```ruby
# frozen_string_literal: true

require_relative "format/version"
require_relative "format/format_helpers"
require_relative "format/content_unit"
require_relative "format/element_analysis"
require_relative "format/element_analyzer"
require_relative "format/format_printer"

module Herb
  module Format
    class Error < StandardError; end

    # Format ERB source code
    #
    # @rbs source: String
    # @rbs config: Config
    # @rbs return: String
    def self.format(source, config:)
      ast = Herb.parse(source, track_whitespace: true)
      FormatPrinter.format(ast, config: config)
    end
  end
end
```

**Test Cases:**
- All modules load
- RBS type checking passes

**Implementation Items:**
- [ ] Enable `context "with inline element that exceeds max line length"` in
  `element_analyzer_spec.rb`: once all visit methods use `push` (instead of
  writing to `PrintContext`), `capture { visit(element) }` will return actual
  rendered lines and the length check will behave correctly

**Estimate:** 1 hour

**Dependencies:** All prior tasks

---

### Task 2.35b: Migrate write-based visitors to push (output unification)

**Purpose:** Unify the two output paths (`write` → `context.output` and `push` → `@lines`)
so that all visitor methods use `push`. This allows `capture { visit(element) }` to return
actual rendered lines, making `ElementAnalyzer` length checks work correctly. It also
eliminates the fallback branch in `formatted_output`.

**Background:** When `visit_erb_content_node` was implemented in Task 2.23, ERB nodes
started using `push` while HTML nodes continued using `write`. This split means mixed
content (e.g. `<div><%= @user.name %></div>`) cannot be tested via `.format`. This task
resolves that technical debt.

**Location:** `herb-format/lib/herb/format/format_printer.rb`

**Implementation Items:**

1. **Migrate HTML visitor methods from `write` to `push_to_last_line`**

   Tokens within the same tag must be concatenated without a newline separator,
   so use `push_to_last_line` to build up a single line.

   ```ruby
   # visit_html_open_tag_node
   def visit_html_open_tag_node(node)
     push_to_last_line(node.tag_opening.value)
     push_to_last_line(node.tag_name.value)
     push_to_last_line(render_attributes_inline(node))
     push_to_last_line(node.tag_closing.value)
   end

   # visit_html_close_tag_node
   def visit_html_close_tag_node(node)
     push_to_last_line(node.tag_opening.value)
     push_to_last_line(node.tag_name.value) if node.tag_name
     push_to_last_line(node.tag_closing.value)
   end

   # visit_literal_node
   def visit_literal_node(node)
     push_to_last_line(node.content)
   end

   # visit_html_text_node
   def visit_html_text_node(node)
     push_to_last_line(node.content)
   end

   # visit_whitespace_node
   def visit_whitespace_node(node)
     push_to_last_line(node.value.value) if node.value
   end
   ```

   Also migrate the `write` calls in preserved elements (`<script>`, `<style>`, `<pre>`, `<textarea>`):
   ```ruby
   node.body.each do |child|
     push_to_last_line(::Herb::Printer::IdentityPrinter.print(child))
   end
   ```

2. **Simplify `formatted_output`**

   Remove the fallback branch; always return `@lines`:
   ```ruby
   def formatted_output #: String
     @lines.join("\n")
   end
   ```

3. **Enable the pending test in `element_analyzer_spec.rb`**

   ```ruby
   # Before:
   pending "Enable once visit methods use push instead of write (Task 2.35)"

   # After:
   context "with inline element that exceeds max line length" do
     # ... actual test
   end
   ```

4. **Migrate `#visit_erb_content_node` unit tests to `.format` integration tests**

   After unifying to `push`, integration tests via `.format` are more natural than
   unit tests via `capture { visit(node) }`, so migrate where possible.

   The indentation and inline mode tests in `describe "#visit_erb_content_node"` cannot
   be expressed through `.format` at this level, so keep them as unit tests.

**Test Cases:**
- `<div><%= @user.name %></div>` → `<div><%= @user.name %></div>` (mixed HTML+ERB)
- All existing HTML-only tests continue to pass
- `element_analyzer_spec.rb` length check test passes

**Estimate:** 2 hours

**Dependencies:** Task 2.35, all ERB visitor methods from Task 2.23 onward

---

### Task 2.35c: Migrate visit_erb_if_node tests to use `.format` as entry point

**Purpose:** Replace the `printer.visit(node)` entry point in `#visit_erb_if_node` tests
with `described_class.format(ast, format_context:)`, so the full formatting pipeline is
exercised end-to-end. This requires wiring inline-mode ERB through the HTML open-tag
visitor path.

**Location:** `herb-format/lib/herb/format/format_printer.rb`,
`herb-format/spec/herb/format/format_printer_spec.rb`

**Background:**

Currently `visit_html_open_tag_node` delegates to `render_attributes_inline`, which
only selects `HTMLAttributeNode` children and returns a `String` via the `write`-based
context. ERBIfNode children in the open tag (and ERBIfNode inside attribute values) are
never routed through `printer.visit` with `inline_mode = true`, so the formatting logic
in `visit_erb_if_inline` is unreachable from `.format`.

Two gaps must be closed (both unblocked by Task 2.35b completing the write-to-push migration):

1. **ERBIfNode directly in open tag** (`<div <% if disabled %>class="disabled"<% end %>>`)
   `render_attributes_inline` skips non-`HTMLAttributeNode` children. It must also visit
   `ERBIfNode` (and similar control-flow nodes) via `with_inline_mode { visit(child) }`.

2. **ERBIfNode inside attribute value** (`<div class="btn<%if active%>active<%end%>">`)
   `render_attribute_value_content` maps non-`LiteralNode` children through
   `IdentityPrinter` (no formatting). It must instead call `with_inline_mode { visit(child) }`
   and collect push-buffer output for those nodes.

**Implementation Items:**

```ruby
# In render_attributes_inline: also visit ERB control-flow nodes inline
def render_attributes_inline(open_tag) #: String
  parts = open_tag.child_nodes.filter_map do |child|
    case child
    when Herb::AST::HTMLAttributeNode
      " #{render_attribute(child)}"
    when Herb::AST::ERBIfNode, Herb::AST::ERBBlockNode # extend as needed
      captured = capture { with_inline_mode { visit(child) } }
      " #{captured.join}"
    end
  end
  parts.join
end

# In render_attribute_value_content: visit ERB nodes via push-buffer instead of IdentityPrinter
def render_attribute_value_content(attribute_value) #: String
  attribute_value.children.map do |child|
    case child
    when Herb::AST::LiteralNode
      child.content
    when Herb::AST::ERBIfNode, Herb::AST::ERBBlockNode # extend as needed
      captured = capture { with_inline_mode { visit(child) } }
      captured.join
    else
      ::Herb::Printer::IdentityPrinter.print(child)
    end
  end.join
end
```

**After implementation**, update `describe "#visit_erb_if_node"` in the spec to use
`.format` directly:

```ruby
describe ".format" do
  context "with ERB if node in inline mode" do
    context "with ERBIfNode directly in open tag" do
      let(:source) { %(<div <% if disabled %>class="disabled"<% end %>></div>) }

      it "renders condition tag, space, attribute, space before end, and end tag" do
        expect(subject).to eq('<div <% if disabled %> class="disabled" <% end %>>')
      end
    end

    context "with ERBIfNode in token-list attribute (class)" do
      let(:source) { %(<div class="btn<%if active%>active<%end%>">) }

      it "adds spaces in token-list context" do
        expect(subject).to include('<div class="btn <% if active %> active <% end %>">')
      end
    end

    context "with ERBIfNode in non-token-list attribute (id)" do
      let(:source) { %(<div id="<%if cond%>active<%end%>">) }

      it "does not add extra spaces" do
        expect(subject).to include('<div id="<% if cond %>active<% end %>">')
      end
    end
  end
end
```

**Test Cases:**
- ERBIfNode directly in HTML open tag rendered via `.format` with correct spacing
- ERBIfNode in `class` attribute (token-list) adds spaces via `.format`
- ERBIfNode in `data-controller` attribute (token-list) adds spaces via `.format`
- ERBIfNode in `data-action` attribute (token-list) adds spaces via `.format`
- ERBIfNode in `id` attribute (non-token-list) produces no extra spaces via `.format`

**Estimate:** 2 hours

**Dependencies:** Task 2.24, Task 2.35b (write-to-push migration must complete first)

---

### Task 2.36: Integration Tests

**Purpose:** Integration tests with real ERB templates

**Location:** `herb-format/spec/herb/format/integration/formatting_spec.rb`

**Implementation Items:**

**Test Cases:**

1. **Simple HTML**
   ```erb
   # Input
   <div><p>Hello</p></div>

   # Output
   <div>
     <p>Hello</p>
   </div>
   ```

2. **Inline Elements**
   ```erb
   # Input
   <p>Hello <strong>world</strong>!</p>

   # Output
   <p>Hello <strong>world</strong>!</p>
   ```

3. **ERB Tags**
   ```erb
   # Input
   <%=@user.name%>

   # Output
   <%= @user.name %>
   ```

4. **ERB Blocks**
   ```erb
   # Input
   <ul><% @users.each do |user| %><li><%=user.name%></li><% end %></ul>

   # Output
   <ul>
     <% @users.each do |user| %>
       <li><%= user.name %></li>
     <% end %>
   </ul>
   ```

5. **Preserved Content**
   ```erb
   # Input
   <pre>  code  </pre>

   # Output
   <pre>  code  </pre>
   ```

6. **User Spacing**
   ```erb
   # Input
   <div>
     <p>First</p>


     <p>Second</p>
   </div>

   # Output
   <div>
     <p>First</p>

     <p>Second</p>
   </div>
   ```

7. **Attribute Wrapping**
   ```erb
   # Input (long attributes)
   <button type="submit" class="btn btn-primary btn-lg" data-action="click->form#submit">

   # Output
   <button
     type="submit"
     class="btn btn-primary btn-lg"
     data-action="click->form#submit"
   >
   ```

- [ ] Review and migrate private method tests in `format_printer_spec.rb`
  - Replace `#capture` tests with integration-level coverage (the save/restore semantics are verified via correct formatted output)
  - Replace `push_with_indent` / `push_to_last_line` tests with integration coverage
  - Keep the `#push` newline counting test (`@string_line_count` increments by the number of `\n` characters) — this contract is subtle and not easily observable through formatted output alone

**Estimate:** 4 hours

**Dependencies:** Task 2.35

---

### Task 2.37: TypeScript Output Comparison

**Purpose:** Compare output with TypeScript implementation

**Location:** `herb-format/spec/herb/format/integration/typescript_comparison_spec.rb`

**Implementation Items:**

```ruby
RSpec.describe "TypeScript Comparison" do
  # Compare with TypeScript sample files and expected output

  FIXTURES_DIR = File.join(__dir__, "fixtures")
  TS_OUTPUT_DIR = File.join(__dir__, "typescript_output")

  Dir.glob(File.join(FIXTURES_DIR, "*.erb")).each do |fixture_file|
    basename = File.basename(fixture_file, ".erb")

    it "matches TypeScript output for #{basename}" do
      input = File.read(fixture_file)
      ts_output_file = File.join(TS_OUTPUT_DIR, "#{basename}_formatted.erb")

      skip "TypeScript output not available" unless File.exist?(ts_output_file)

      ts_output = File.read(ts_output_file)

      config = build(:formatter_config, indent_width: 2, max_line_length: 80)
      ruby_output = Herb::Format.format(input, config: config)

      expect(ruby_output).to eq(ts_output)
    end
  end
end
```

**Estimate:** 3 hours (including fixture creation)

**Dependencies:** Task 2.36

---

### Task 2.38: Performance & Edge Cases

**Purpose:** Performance tests and edge case tests

**Location:** `herb-format/spec/herb/format/integration/performance_spec.rb`

**Implementation Items:**

**Performance Tests:**
- Large file formatting time (10,000 lines)
- Deeply nested elements (100 levels)
- Cache effectiveness verification

**Edge Case Tests:**
- Empty file
- Whitespace only
- Deep nesting
- Long lines (1,000 characters)
- Special characters (UTF-8, emojis)
- Broken HTML
- Complex ERB (nested if, each)

**Estimate:** 3 hours

**Dependencies:** Task 2.36

---

### Task 2.39: Full Verification

**Purpose:** Complete verification checklist

**Implementation Items:**

- [ ] `cd herb-format && ./bin/rake` - All checks pass
  - [ ] RSpec tests
  - [ ] Rubocop
  - [ ] Steep type checking
- [ ] Basic formatting works
  - [ ] Indentation and newlines
  - [ ] Inline elements on one line
  - [ ] ERB tag normalization
- [ ] Attribute formatting
  - [ ] Inline vs multiline
  - [ ] Class attribute wrapping
  - [ ] Quote normalization
- [ ] ERB formatting
  - [ ] Control flow (if, unless, each)
  - [ ] Indentation
  - [ ] Comments
- [ ] Special cases
  - [ ] Content-preserving elements
  - [ ] User spacing preservation
  - [ ] herb:disable
- [ ] TypeScript compatibility
  - [ ] Same output for sample files

**Estimate:** 2 hours

**Dependencies:** All prior tasks

---

**Part G Summary:**
- **Total Tasks:** 5 tasks
- **Estimate:** 13-15 hours
- **Difficulty:** Medium (mostly testing)

---

## 📊 Phase 2 Overall Summary

### Task Count and Estimates

| Part | Tasks | Estimate | Difficulty |
|------|-------|----------|------------|
| A: FormatHelpers | 8 | 10-12h | Medium |
| B: Core Patterns | 5 | 4-5h | Medium |
| C: ElementAnalyzer | 4 | 8-10h | Highest |
| D: Attribute Formatting | 4 | 8-10h | High |
| E: ERB Formatting | 7 | 14-16h | High |
| F: Text Flow & Spacing | 6 | 13-15h | Highest |
| G: Integration & Testing | 5 | 13-15h | Medium |
| **Total** | **39** | **70-83h** | **Very High** |

### Critical Path

```
Part A (FormatHelpers)
  ↓
Part B (Core Patterns) + Part C (ElementAnalyzer)
  ↓
Part D (Attributes) + Part E (ERB) + Part F (Text Flow)
  ↓
Part G (Integration & Testing)
```

### Recommended Implementation Order

**Week 1-2: Foundation (Part A, B)**
- Task 2.1-2.8: FormatHelpers
- Task 2.9-2.13: Core Patterns

**Week 3-4: Analysis Engine (Part C)**
- Task 2.14-2.17: ElementAnalyzer

**Week 5-6: Formatting (Part D, E)**
- Task 2.18-2.21: Attributes
- Task 2.22-2.28: ERB

**Week 7-8: Advanced Features (Part F)**
- Task 2.29-2.34: Text Flow & Spacing

**Week 9-10: Integration and Testing (Part G)**
- Task 2.35-2.39: Integration & Testing

---

## 🎯 Next Steps

1. **Start Implementation from Part A**
   - Complete FormatHelpers module
   - Build comprehensive tests

2. **Early Feedback**
   - Test simple formatting after Part B completion
   - Start TypeScript output comparison

3. **Continuous Verification**
   - Integration tests after each Part completion
   - Performance measurement

---

**Ready to implement!**
