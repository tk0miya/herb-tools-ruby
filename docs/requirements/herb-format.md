# herb-format Specification

Formatter for ERB templates.

## CLI Interface

### Synopsis

```bash
herb-format [options] [files...]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `files...` | Files or directories to format. If omitted, uses paths from configuration. |

### Options

| Option | Description |
|--------|-------------|
| `--init` | Generate a default `.herb.yml` configuration file |
| `--check` | Check if files are formatted without modifying them |
| `--force` | Override inline ignore directives |
| `--stdin` | Read from standard input (output to stdout) |
| `--stdin-filepath <path>` | Path to use for configuration lookup when using stdin |
| `--config <path>` | Path to configuration file (default: `.herb.yml`) |
| `--write` | Write formatted output back to files (default behavior) |
| `--version` | Show version number |
| `--help` | Show help message |

### Exit Codes

| Code | Description |
|------|-------------|
| 0 | All files formatted (or already formatted with `--check`) |
| 1 | Files need formatting (with `--check`) or formatting error |
| 2 | Invalid configuration or runtime error |

### Examples

```bash
# Format all files in current directory
herb-format

# Format specific files
herb-format app/views/users/index.html.erb

# Format directory
herb-format app/views/

# Initialize configuration
herb-format --init

# Check without modifying (for CI)
herb-format --check

# Format from stdin
echo '<div><p>Hello</p></div>' | herb-format --stdin

# Format stdin with config resolution
cat template.erb | herb-format --stdin --stdin-filepath app/views/template.erb

# Force format ignored files
herb-format --force app/views/legacy/
```

## Configuration

See [Configuration Specification](./config.md) for full details.

### Basic Formatter Configuration

```yaml
formatter:
  enabled: true
  indentWidth: 2
  maxLineLength: 80
  include:
    - "**/*.html.erb"
    - "**/*.turbo_stream.erb"
  exclude:
    - "vendor/**"
    - "node_modules/**"
  rewriter:
    pre: []
    post:
      - tailwind-class-sorter
```

## Inline Directives

### File-level Ignore

Add at the top of the file to skip formatting entirely:

```erb
<%# herb:formatter ignore %>
<!-- Rest of file is not formatted -->
```

### Range Ignore

Disable formatting for a specific range:

```erb
<%# herb:formatter off %>
<pre>
  This    content   preserves
  its     exact     formatting
</pre>
<%# herb:formatter on %>
```

## Formatting Rules

### Indentation

- Uses spaces (configurable width, default: 2)
- Indents nested elements
- Aligns closing tags with opening tags
- Respects ERB block indentation

**Before:**
```erb
<div>
<p>
Hello
</p>
</div>
```

**After (indentWidth: 2):**
```erb
<div>
  <p>
    Hello
  </p>
</div>
```

### Line Length

- Wraps long lines at `maxLineLength` (default: 80)
- Wraps attributes to separate lines when exceeded
- Preserves pre/code content

**Before:**
```erb
<button type="submit" class="btn btn-primary btn-lg" data-action="click->form#submit" data-controller="tooltip" title="Submit the form">
  Submit
</button>
```

**After (maxLineLength: 80):**
```erb
<button
  type="submit"
  class="btn btn-primary btn-lg"
  data-action="click->form#submit"
  data-controller="tooltip"
  title="Submit the form"
>
  Submit
</button>
```

### Attribute Formatting

- Single attribute: keep on same line
- Multiple attributes with overflow: one per line
- Consistent quote style (double quotes)
- Sorted attributes (optional, via rewriter)

### Whitespace

- Removes trailing whitespace
- Normalizes line endings (LF)
- Ensures single blank line between major blocks
- Removes excessive blank lines

### ERB Tag Formatting

- Consistent spacing inside ERB tags
- Aligns multi-line ERB expressions
- Preserves ERB comments

**Before:**
```erb
<%=@user.name%>
<%   if @show   %>
```

**After:**
```erb
<%= @user.name %>
<% if @show %>
```

### Void Elements

- Consistent style for void elements (e.g., `<br>`, `<img>`, `<input>`)
- Omits closing slash by default

**Before:**
```erb
<br/>
<img src="photo.jpg" />
<input type="text"/>
```

**After:**
```erb
<br>
<img src="photo.jpg">
<input type="text">
```

### Preserved Content

The following content is not reformatted:

- `<pre>` and `<code>` blocks
- `<script>` and `<style>` content
- Content within `<%# herb:formatter off %>` ranges
- Ignored files

## Rewriters

Rewriters are plugins that transform the AST before or after formatting.

### Configuration

```yaml
formatter:
  rewriter:
    pre:
      - normalize-attributes    # Runs before formatting
    post:
      - tailwind-class-sorter   # Runs after formatting
```

### Execution Order

1. Parse template to AST
2. Run **pre-rewriters** (in order)
3. Apply formatting rules
4. Run **post-rewriters** (in order)
5. Serialize AST back to template

### Built-in Rewriters

| Rewriter | Phase | Description |
|----------|-------|-------------|
| `tailwind-class-sorter` | post | Sort Tailwind CSS classes |
| `normalize-attributes` | pre | Normalize attribute formatting |
| `sort-attributes` | post | Alphabetically sort attributes |

### Custom Rewriters

Custom rewriters can be loaded from `.herb/rewriters/*.rb`.

```ruby
# .herb/rewriters/custom_sorter.rb
module Herb
  module Format
    module Rewriters
      class CustomSorter < Base
        def self.rewriter_name
          "custom-sorter"
        end

        def self.phase
          :post
        end

        def rewrite(ast, context)
          # Transform and return modified AST
          ast
        end
      end
    end
  end
end
```

### Rewriter Base Class

```ruby
module Herb
  module Format
    module Rewriters
      class Base
        # @return [String] Rewriter identifier (kebab-case)
        def self.rewriter_name
          raise NotImplementedError
        end

        # @return [Symbol] Execution phase (:pre or :post)
        def self.phase
          :post
        end

        # @param ast [Herb::AST::Document] The parsed template
        # @param context [Herb::Format::Context] Formatting context
        # @return [Herb::AST::Document] Modified AST
        def rewrite(ast, context)
          raise NotImplementedError
        end
      end
    end
  end
end
```

## Internal Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                         CLI                             │
│  (argument parsing, file discovery, stdin handling)     │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                      Formatter                          │
│  (orchestrates formatting pipeline)                     │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                       Config                            │
│  (loads .herb.yml, resolves settings)                   │
└───────────────────────────┬─────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────┐ ┌──────────────┐ ┌─────────────────┐
│  Pre-Rewriters  │ │  Formatting  │ │  Post-Rewriters │
│                 │ │ FormatPrinter│ │                 │
└─────────────────┘ └──────────────┘ └─────────────────┘
```

### Processing Flow

1. CLI parses arguments and options
2. Config loads `.herb.yml` and resolves settings
3. Formatter discovers files matching include/exclude patterns
4. For each file:
   a. Read file content
   b. Check for file-level ignore directive (unless `--force`)
   c. Parse with `herb` gem to get AST
   d. Run pre-rewriters
   e. Apply formatting rules to AST
   f. Run post-rewriters
   g. Serialize AST back to string
   h. If `--check`: compare with original
   i. If writing: update file (or output to stdout)
5. Report results
6. Return appropriate exit code

### FormatPrinter

The FormatPrinter extends `Herb::Printer::Base` (which extends `Herb::Visitor`) to traverse the AST and produce formatted output using the visitor pattern with double-dispatch:

```ruby
module Herb
  module Format
    class FormatPrinter < ::Herb::Printer::Base
      def self.format(input, format_context:, ignore_errors: false)
        node = input.is_a?(::Herb::ParseResult) ? input.value : input
        validate_no_errors!(node) unless ignore_errors

        printer = new(
          indent_width: format_context.indent_width,
          max_line_length: format_context.max_line_length,
          format_context:
        )
        printer.visit(node)
        printer.context.output
      end

      # Visitor method overrides for each node type
      def visit_literal_node(node)
        write(node.content)
      end

      def visit_html_text_node(node)
        write(node.content)
      end

      # ... other visitor methods
    end
  end
end
```

## Diff Output

When using `--check`, the formatter shows a diff of needed changes:

```diff
--- app/views/users/index.html.erb
+++ app/views/users/index.html.erb (formatted)
@@ -1,5 +1,5 @@
 <div class="container">
-<p>
-Hello
-</p>
+  <p>
+    Hello
+  </p>
 </div>
```

## Stdin/Stdout Mode

When using `--stdin`:

1. Read template content from stdin
2. Apply formatting
3. Write formatted content to stdout
4. Exit with code 0 (success) or 1 (error)

The `--stdin-filepath` option allows configuration lookup based on a virtual path:

```bash
# Use config from app/views context
cat template.erb | herb-format --stdin --stdin-filepath app/views/template.erb
```

## Related Documents

- [Configuration Specification](./config.md)
- [Project Overview](./overview.md)
