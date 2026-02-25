# Herb AST Reference

Quick reference for all 28 node types produced by `Herb.parse`. Covers properties,
Token vs Node distinction, and common access patterns.

> Always call `Herb.parse(source, track_whitespace: true)`. Omitting this option drops
> `WhitespaceNode`s from the tree, which breaks lossless round-tripping and some rules.

## Quick Reference

| Node class | Category | Token properties | Node/Array properties |
|---|---|---|---|
| `DocumentNode` | Root | — | `children` |
| `LiteralNode` | Leaf | — | — (`content`: String) |
| `HTMLTextNode` | Leaf | — | — (`content`: String) |
| `WhitespaceNode` | Leaf | `value`? | — |
| `HTMLElementNode` | HTML structure | `tag_name`? *(shortcut)* | `open_tag`, `close_tag`?, `body` |
| `HTMLOpenTagNode` | HTML structure | `tag_opening`, `tag_name`, `tag_closing` | `children` (ws + attrs) |
| `HTMLCloseTagNode` | HTML structure | `tag_opening`, `tag_name` *(not a child)*, `tag_closing` | `children` (ws only) |
| `HTMLAttributeNode` | HTML attribute | `equals`? | `name`, `value`? |
| `HTMLAttributeNameNode` | HTML attribute | — | `children` (LiteralNodes) |
| `HTMLAttributeValueNode` | HTML attribute | `open_quote`?, `close_quote`? | `children` |
| `HTMLDoctypeNode` | HTML special | `tag_opening`, `tag_closing` | `children` (LiteralNodes) |
| `HTMLCommentNode` | HTML special | `comment_start`, `comment_end` | `children` (LiteralNodes) |
| `XMLDeclarationNode` | HTML special | `tag_opening`, `tag_closing` | `children` (LiteralNodes) |
| `ERBContentNode` | ERB leaf | `tag_opening`, `content`, `tag_closing` | — |
| `ERBYieldNode` | ERB leaf | `tag_opening`, `content`, `tag_closing` | — |
| `ERBEndNode` | ERB leaf | `tag_opening`, `content`, `tag_closing` | — |
| `ERBElseNode` | ERB leaf | `tag_opening`, `content`, `tag_closing` | `statements` |
| `ERBIfNode` | ERB control | `tag_opening`, `content`, `tag_closing`, `then_keyword`? | `statements`, `subsequent`?, `end_node`? |
| `ERBUnlessNode` | ERB control | `tag_opening`, `content`, `tag_closing`, `then_keyword`? | `statements`, `subsequent`?, `end_node`? |
| `ERBCaseNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `conditions`, `else_clause`?, `end_node`? |
| `ERBCaseMatchNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `conditions`, `else_clause`?, `end_node`? |
| `ERBWhenNode` | ERB control | `tag_opening`, `content`, `tag_closing`, `then_keyword`? | `statements` |
| `ERBInNode` | ERB control | `tag_opening`, `content`, `tag_closing`, `then_keyword`? | `statements` |
| `ERBBlockNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `body`, `end_node`? |
| `ERBForNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `statements`, `end_node`? |
| `ERBWhileNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `statements`, `end_node`? |
| `ERBUntilNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `statements`, `end_node`? |
| `ERBBeginNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `statements`, `rescue_clause`?, `else_clause`?, `ensure_clause`?, `end_node`? |
| `ERBRescueNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `statements`, `subsequent`? |
| `ERBEnsureNode` | ERB control | `tag_opening`, `content`, `tag_closing` | `statements` |

## Token vs Node Properties

**This is the most important concept when working with this AST.**

`child_nodes` returns only **Node** children. **Token** properties (raw source fragments) are
separate and must be accessed explicitly.

```ruby
# Token: raw string fragment — access via .value
node.tag_opening.value   # => "<%="
node.tag_closing.value   # => "%>"
node.content.value       # => " user.name "

# Token also has location
node.tag_opening.location.start.line   # => 1 (1-indexed)
node.tag_opening.location.start.column # => 0 (0-indexed)
```

Consequence for `IdentityPrinter` and `FormatPrinter`: calling `visit_child_nodes` alone
skips all Token content. ERB node visit methods must call `print_erb_tag` (for Tokens) AND
`super` (for Node children) separately.

`HTMLCloseTagNode` is the most surprising case: its `tag_name` is a Token, not a child node,
but whitespace Nodes can appear on both sides of it (e.g. `</ div >`). Use
`nodes_before_token` / `nodes_after_token` to partition children around the token position.

## Node Mutability

AST nodes are **read-only by API design**. Understanding the boundary is important for
writing rewriters and formatters.

### No setter methods

No node class defines setter methods (`attr_writer` / `attr_accessor`). Every attribute
is exposed via `attr_reader` only. Direct attribute reassignment always raises
`NoMethodError`:

```ruby
node.children = []          # => NoMethodError: undefined method `children='
node.open_tag = other_tag   # => NoMethodError: undefined method `open_tag='
token.value = "span"        # => NoMethodError: undefined method `value='
```

### Array properties can be mutated in place

Array properties (`children`, `body`, `statements`, `conditions`) are standard Ruby
arrays and are not frozen. You can modify their contents through normal Array operations:

```ruby
# Replace a child node in an Array property
element.body[0] = new_child_node

# Remove / append children
element.body.delete_at(1)
element.body.push(new_node)
```

### Scalar properties are not reassignable

Properties that hold a single node or Token (`open_tag`, `close_tag`, `name`, `value`,
`subsequent`, `end_node`, etc.) have no setter. If you need to change these, re-parse
the modified source or construct a new parent node.

### Recommended pattern for AST rewriting

For rewriters (`Herb::Format::Rewriters::Base`), swap elements in the parent's Array
property to replace subtrees:

```ruby
parent.body[index] = build_replacement_node(original)
```

For changes that require modifying scalar properties (e.g. changing a tag name), the
idiomatic approach is to re-parse the desired source fragment with `Herb.parse` rather
than attempting to mutate existing nodes.

## Common Properties (all nodes)

```ruby
node.location               # Herb::Location
node.location.start         # Herb::Position — .line (1-indexed), .column (0-indexed)
node.location.end           # Herb::Position — .line, .column

node.child_nodes            # Array[Node] — Node children only (no Tokens)
node.children               # Array[Node] — same as child_nodes on most nodes; on
                            #   DocumentNode/HTMLOpenTagNode it includes all children
node.recursive_errors       # Array — all parse errors in this subtree
node.type                   # Symbol node type name
```

## Node Details

### HTML Structure

**`HTMLElementNode`**
```
open_tag   → HTMLOpenTagNode
tag_name   → Token (shortcut to open_tag.tag_name; nil for malformed)
body       → Array[Node]   (text, child elements, ERB nodes)
close_tag  → HTMLCloseTagNode?  (nil for void elements)
is_void    → bool
source     → String  ("HTML" or "SVG")
```

**`HTMLOpenTagNode`** — `<div class="a">`
```
tag_opening → Token  ("<")
tag_name    → Token  ("div")
tag_closing → Token  (">")
children    → Array[Node]  (WhitespaceNode + HTMLAttributeNode interleaved)
is_void     → bool
```
Attributes live in `children`. Use `NodeHelpers#attributes(element_node)` rather than
accessing `open_tag.children` directly.

**`HTMLCloseTagNode`** — `</div>`
```
tag_opening → Token  ("</")
tag_name    → Token  ("div")  ← NOT in child_nodes
tag_closing → Token  (">")
children    → Array[Node]  (WhitespaceNode only, e.g. `</ div >`)
```

**`HTMLAttributeNode`** — `class="a"` or `disabled`
```
name   → HTMLAttributeNameNode
equals → Token?              (nil for boolean attributes)
value  → HTMLAttributeValueNode?  (nil for boolean attributes)
```

**`HTMLAttributeNameNode`** — `class`
```
children → Array[LiteralNode]
# Quick extraction:
node.name.children.first&.content  # => "class"
```

**`HTMLAttributeValueNode`** — `"a"` or `"<%= x %>"`
```
open_quote  → Token?  (nil for unquoted attributes)
close_quote → Token?
children    → Array[Node]  (LiteralNode, ERBContentNode, etc.)
quoted      → bool
# Simple static value:
node.value.children.first&.content  # => "a"
# Complex value (contains ERB): serialize with Herb::Printer::IdentityPrinter.print(node.value)
```

### HTML Special Nodes

**`HTMLDoctypeNode`** — `<!DOCTYPE html>`
```
tag_opening → Token  ("<!DOCTYPE")
tag_closing → Token  (">")
children    → Array[LiteralNode]  (" html")
```

**`HTMLCommentNode`** — `<!-- text -->`
```
comment_start → Token  ("<!--")
comment_end   → Token  ("-->")
children      → Array[LiteralNode]
```

**`XMLDeclarationNode`** — `<?xml version="1.0"?>`
```
tag_opening → Token  ("<?xml")
tag_closing → Token  ("?>")
children    → Array[LiteralNode]  (' version="1.0"')
```

### Leaf Nodes

**`LiteralNode`** — plain text, attribute content
```
content → String
```

**`HTMLTextNode`** — text between HTML tags
```
content → String
```

**`WhitespaceNode`** — preserved whitespace (requires `track_whitespace: true`)
```
value → Token?
# Access string: node.value.value
```

### ERB Leaf Nodes

All three share the ERB token triple:
```
tag_opening → Token  ("<%", "<%=", "<%#", etc.)
content     → Token  (everything between delimiters)
tag_closing → Token  ("%>", "-%>", etc.)
```

**`ERBContentNode`** — `<%= expr %>` and `<%# comment %>`
```
# Distinguish output (<%=) from comment (<%#):
node.tag_opening.value == "<%="   # output tag
node.tag_opening.value == "<%#"   # comment tag
parsed       → bool
valid        → bool
```

**`ERBYieldNode`** — `<%= yield %>`
**`ERBEndNode`** — `<% end %>`
(ERB token triple only)

**`ERBElseNode`** — `<% else %>` (used in if/unless and begin/rescue chains)
```
statements → Array[Node]
```

### ERB Control Flow Nodes

**`ERBIfNode`** / **`ERBUnlessNode`**
```
tag_opening  → Token
content      → Token  (" if condition " / " elsif condition " / " unless condition ")
tag_closing  → Token
then_keyword → Token?  (for `<% if x then %>` style)
statements   → Array[Node]   (body of this branch)
subsequent   → ERBIfNode | ERBElseNode | nil
              # if:     chains elsif (ERBIfNode) → else (ERBElseNode) → nil
              # unless: nil or ERBElseNode directly
end_node     → ERBEndNode?   (present on outermost; nil on elsif nodes)
```
Walk the chain: `node.subsequent` until `nil`. `end_node` is on the first node only.

**`ERBCaseNode`** — `<% case x %>` / `<% when ... %>`
**`ERBCaseMatchNode`** — `<% case x %>` / `<% in ... %>`
```
tag_opening → Token
content     → Token  (" case x ")
tag_closing → Token
conditions  → Array[ERBWhenNode]  (or Array[ERBInNode] for case/in)
else_clause → ERBElseNode?
end_node    → ERBEndNode?
```

**`ERBWhenNode`** — `<% when 1 %>`
**`ERBInNode`** — `<% in [x] %>`
```
tag_opening  → Token
content      → Token
tag_closing  → Token
then_keyword → Token?
statements   → Array[Node]
```

**`ERBBlockNode`** — `<% items.each do |i| %>`
```
tag_opening → Token
content     → Token  (" items.each do |i| ")
tag_closing → Token
body        → Array[Node]
end_node    → ERBEndNode?
```
Note: uses `body` (not `statements`), same as `HTMLElementNode`.

**`ERBForNode`** / **`ERBWhileNode`** / **`ERBUntilNode`**
```
tag_opening → Token
content     → Token
tag_closing → Token
statements  → Array[Node]
end_node    → ERBEndNode?
```

**`ERBBeginNode`** — `<% begin %>`
```
tag_opening   → Token
content       → Token
tag_closing   → Token
statements    → Array[Node]           (begin body)
rescue_clause → ERBRescueNode?        (first rescue; chains via .subsequent)
else_clause   → ERBElseNode?          (else after all rescues; no-exception branch)
ensure_clause → ERBEnsureNode?
end_node      → ERBEndNode?
```

**`ERBRescueNode`** — `<% rescue TypeError => e %>`
```
tag_opening → Token  (content holds exception class + binding if present)
content     → Token
tag_closing → Token
statements  → Array[Node]
subsequent  → ERBRescueNode?   (next rescue clause, if any)
```

**`ERBEnsureNode`** — `<% ensure %>`
```
tag_opening → Token
content     → Token
tag_closing → Token
statements  → Array[Node]
```

## Common Patterns

```ruby
# Get tag name (lowercase) from an element
node.tag_name&.value&.downcase   # direct
tag_name(node)                   # via NodeHelpers (lint rules)

# Get all attributes from an element
node.open_tag.children.select { _1.is_a?(Herb::AST::HTMLAttributeNode) }
attributes(node)                 # via NodeHelpers (lint rules)

# Read a static attribute value
find_attribute(node, "href")&.then { attribute_value(_1) }

# Check if attribute value is purely static (no ERB)
node.value.children.all? { _1.is_a?(Herb::AST::LiteralNode) }

# Serialize any node back to source
Herb::Printer::IdentityPrinter.print(node)

# Check ERB tag type (output vs silent vs comment)
node.tag_opening.value          # "<%=", "<%", "<%#", "<%#"

# Detect void elements
node.is_void                    # bool on HTMLElementNode and HTMLOpenTagNode
node.close_tag.nil?             # equivalent check on HTMLElementNode

# Walk if/elsif/else chain
curr = if_node
while curr
  curr = curr.subsequent   # ERBIfNode (elsif) → ERBElseNode → nil
end
```
