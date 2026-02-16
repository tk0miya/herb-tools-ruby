# Formatting Rules Specification

Detailed formatting rules for herb-format, based on TypeScript reference implementation.

## Overview

herb-format uses intelligent formatting decisions based on element type, content structure, and user intent.

## Core Principles

1. **Inline by default for inline elements** - Elements like `<span>`, `<a>`, `<em>` stay on one line
2. **Block formatting for structure** - Elements like `<div>`, `<p>`, `<section>` use multi-line formatting
3. **Content preservation** - Never reformat `<pre>`, `<code>`, `<script>`, `<style>`
4. **User intent preservation** - Respect intentional blank lines (double newlines)
5. **Whitespace normalization** - Remove trailing whitespace, normalize spacing

## Element Classification

### Inline Elements

Elements that should stay on one line when their content is simple:

```
a, abbr, acronym, b, bdo, big, br, cite, code, dfn, em, hr, i, img,
kbd, label, map, object, q, samp, small, span, strong, sub, sup, tt,
var, del, ins, mark, s, u, time, wbr
```

### Block Elements

All other elements (div, p, section, etc.)

### Content-Preserving Elements

Content is never reformatted inside these elements:

```
script, style, pre, textarea
```

## Formatting Decision Logic

### Decision Tree for HTMLElementNode

```
Is element content-preserving (pre, code, script, style)?
├─ YES → Use IdentityPrinter (preserve exactly as-is)
└─ NO → Continue

Is element void (br, img, input, etc.)?
├─ YES → Format inline (no close tag)
└─ NO → Continue

Is element body empty?
├─ YES → Format inline (<div></div>)
└─ NO → Continue

Does element have single simple text child?
├─ YES → Format inline (<p>Hello</p>)
└─ NO → Continue

Are all nested elements inline with no complex structure?
├─ YES → Format inline (<div><span>A</span><span>B</span></div>)
└─ NO → Continue

Does element have mixed text and inline content?
├─ YES → Format inline (<p>Text <em>emphasis</em> more text</p>)
└─ NO → Format block (multi-line with indentation)
```

### Examples

#### Inline Formatting (One Line)

**Simple text content:**
```erb
# Input
<p>Hello world</p>

# Output
<p>Hello world</p>
```

**Single inline element:**
```erb
# Input
<div>
<span>foo</span>
</div>

# Output (REFINED: This should actually be inline because it's a single inline child)
<div><span>foo</span></div>
```

**Multiple inline elements (no whitespace between):**
```erb
# Input
<p><strong>Bold</strong><em>Italic</em></p>

# Output
<p><strong>Bold</strong><em>Italic</em></p>
```

**Mixed text and inline:**
```erb
# Input
<p>
Text
<em>emphasis</em>
more text
</p>

# Output
<p>Text <em>emphasis</em> more text</p>
```

#### Block Formatting (Multi-Line)

**Nested block elements:**
```erb
# Input
<div><p>Hello</p></div>

# Output
<div>
  <p>Hello</p>
</div>
```

**Multiple children:**
```erb
# Input
<div><p>First</p><p>Second</p></div>

# Output
<div>
  <p>First</p>
  <p>Second</p>
</div>
```

**Complex structure:**
```erb
# Input
<section><header><h1>Title</h1></header><p>Content</p></section>

# Output
<section>
  <header>
    <h1>Title</h1>
  </header>
  <p>Content</p>
</section>
```

## Indentation Rules

### Basic Indentation

- Default: 2 spaces (configurable via `indentWidth`)
- Each nesting level increases indentation
- Closing tags align with opening tags

```erb
<div>              # indent level 0
  <p>              # indent level 1 (2 spaces)
    <span>         # indent level 2 (4 spaces)
      text
    </span>
  </p>
</div>
```

### Inline Elements (No Indentation)

When element is formatted inline, no indentation or newlines are added:

```erb
<p>Hello <strong>world</strong>!</p>
```

### Mixed Block and Inline

Block elements get indentation, inline elements within them stay inline:

```erb
<div>
  <p>Text with <em>emphasis</em> and <strong>bold</strong>.</p>
  <p>Another paragraph.</p>
</div>
```

## Attribute Formatting

### Single Attribute

Keep on same line:

```erb
<div class="container">
```

### Multiple Attributes (Within Line Length)

Keep on same line if under `maxLineLength`:

```erb
<div class="container" id="main">
```

### Multiple Attributes (Exceeds Line Length)

When opening tag exceeds `maxLineLength` (default: 80), wrap to one attribute per line:

```erb
# Input
<button type="submit" class="btn btn-primary btn-lg" data-action="click->form#submit" data-controller="tooltip" title="Submit the form">

# Output (exceeds 80 chars)
<button
  type="submit"
  class="btn btn-primary btn-lg"
  data-action="click->form#submit"
  data-controller="tooltip"
  title="Submit the form"
>
```

### Attribute Value Quotes

Always use double quotes:

```erb
# Input
<div class='foo' id='bar'>

# Output
<div class="foo" id="bar">
```

## Whitespace Handling

### Trailing Whitespace

Remove all trailing whitespace from lines:

```erb
# Input
<div>
  <p>text</p>
</div>

# Output
<div>
  <p>text</p>
</div>
```

### Line Endings

Normalize to LF (`\n`):

```erb
# Input (CRLF)
<div>\r\n  <p>text</p>\r\n</div>

# Output (LF)
<div>
  <p>text</p>
</div>
```

### User Intentional Spacing

Preserve double newlines (blank lines) between elements:

```erb
# Input
<div>
  <p>First paragraph</p>


  <p>Second paragraph</p>
</div>

# Output (blank line preserved)
<div>
  <p>First paragraph</p>

  <p>Second paragraph</p>
</div>
```

### Pure Whitespace Nodes

Remove whitespace-only text nodes except:
- Single space between inline elements
- User intentional spacing (double newlines)

```erb
# Input
<div>

  <p>content</p>

</div>

# Output (whitespace normalized)
<div>
  <p>content</p>
</div>
```

## ERB Tag Formatting

### Spacing Normalization

Ensure single space after opening and before closing:

```erb
# Input
<%=@user.name%>
<%  if  condition  %>
<%#comment%>

# Output
<%= @user.name %>
<% if condition %>
<%# comment %>
```

### ERB in Text Flow

ERB tags in text content stay inline:

```erb
# Input
<p>
Hello
<%= @user.name %>
!
</p>

# Output
<p>Hello <%= @user.name %>!</p>
```

### ERB Control Flow

Multi-line ERB blocks get proper indentation:

```erb
# Input
<% if @show %><div>content</div><% end %>

# Output
<% if @show %>
  <div>content</div>
<% end %>
```

### ERB Blocks

```erb
# Input
<ul><% @items.each do |item| %><li><%= item %></li><% end %></ul>

# Output
<ul>
  <% @items.each do |item| %>
    <li><%= item %></li>
  <% end %>
</ul>
```

## Void Elements

### Self-Closing Slash

Omit closing slash (HTML5 style):

```erb
# Input
<br/>
<img src="photo.jpg" />
<input type="text"/>

# Output
<br>
<img src="photo.jpg">
<input type="text">
```

### Void Element List

```
area, base, br, col, embed, hr, img, input, link, meta, param, source, track, wbr
```

## Content Preservation

### Elements with Preserved Content

Content inside these elements is never reformatted:

```erb
# Input
<pre>
  def hello
    puts 'world'
  end
</pre>

# Output (preserved exactly)
<pre>
  def hello
    puts 'world'
  end
</pre>
```

Same applies to:
- `<script>` - JavaScript code
- `<style>` - CSS code
- `<textarea>` - User input

### Preserved Element List

```
script, style, pre, textarea
```

## Special Cases

### Comments

HTML comments are preserved as-is:

```erb
# Input
<!-- This is a comment -->

# Output (preserved)
<!-- This is a comment -->
```

### DOCTYPE

DOCTYPE declarations are preserved:

```erb
# Input
<!DOCTYPE html>

# Output (preserved)
<!DOCTYPE html>
```

### YAML Frontmatter

YAML frontmatter (if present) is preserved:

```erb
# Input
---
title: Page Title
---

# Output (preserved)
---
title: Page Title
---
```

## Edge Cases

### Empty Elements

```erb
# Input
<div>
</div>

# Output
<div></div>
```

### Elements with Only Whitespace

Treated as empty:

```erb
# Input
<div>

</div>

# Output
<div></div>
```

### Adjacent Inline Elements

Keep together when no whitespace between:

```erb
# Input
<p>
<a>Link1</a><a>Link2</a>
</p>

# Output
<p><a>Link1</a><a>Link2</a></p>
```

### Line-Breaking Elements (br, hr)

`<br>` and `<hr>` maintain their line-breaking semantics:

```erb
# Input
<p>Line 1<br>Line 2</p>

# Output
<p>Line 1<br>Line 2</p>
```

### Herb Disable Comments

Files with `<%# herb:formatter ignore %>` are not formatted at all.

## Formattable Attributes

### Class Attribute

The `class` attribute on any element can be formatted:

```erb
# Input (long class list)
<div class="container mx-auto px-4 py-8 bg-white shadow-lg rounded-lg border border-gray-200">

# Output (if exceeds maxLineLength, wrap to multi-line)
<div
  class="container mx-auto px-4 py-8 bg-white shadow-lg rounded-lg border border-gray-200"
>
```

### Image Attributes

`srcset` and `sizes` on `<img>` elements:

```erb
# Input
<img srcset="small.jpg 480w, medium.jpg 800w, large.jpg 1200w" sizes="(max-width: 600px) 480px, 800px">

# Output (if exceeds maxLineLength)
<img
  srcset="small.jpg 480w, medium.jpg 800w, large.jpg 1200w"
  sizes="(max-width: 600px) 480px, 800px"
>
```

## Summary Table

| Element Type | Content Type | Formatting | Example |
|--------------|--------------|------------|---------|
| Void | N/A | Inline, no close tag | `<br>`, `<img>` |
| Inline | Simple text | Inline | `<span>text</span>` |
| Inline | Mixed inline | Inline | `<p>Text <em>word</em></p>` |
| Block | Simple text | Inline | `<p>Hello</p>` |
| Block | Nested block | Block (multi-line) | `<div><p>...</p></div>` |
| Block | Multiple children | Block (multi-line) | `<div><p>A</p><p>B</p></div>` |
| Preserving | Any | Preserved exactly | `<pre>code</pre>` |

## Implementation Notes

### ElementFormattingAnalysis

The TypeScript implementation uses a 3-field analysis structure:

```typescript
{
  openTagInline: boolean,      // Should open tag be on same line as parent?
  elementContentInline: boolean, // Should content be inline?
  closeTagInline: boolean      // Should close tag be on same line?
}
```

This allows fine-grained control:
- `{ true, true, true }` - Fully inline: `<p>text</p>`
- `{ false, false, false }` - Block format with newlines
- Mixed values allow partial inline formatting

### Future Enhancements

**Text Wrapping:**
- Currently, text within elements is not wrapped at `maxLineLength`
- Future: Implement intelligent text wrapping that respects word boundaries

**Attribute Sorting:**
- Can be implemented via rewriters (post-formatting phase)
- Not part of core formatting logic

**Class Sorting:**
- Tailwind CSS class sorting via `tailwind-class-sorter` rewriter
- Not part of core formatting logic
