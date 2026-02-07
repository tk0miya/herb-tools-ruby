# herb-lint Specification

Static analysis tool for ERB templates.

## Implementation Status

This specification describes the full feature set for herb-lint. The implementation is being developed incrementally:

### MVP (Minimum Viable Product) - ✅ Complete

The MVP provides core linting functionality:

- **Configuration**: Basic `.herb.yml` loading (linter.rules section only)
- **File Discovery**: Simple pattern matching (`**/*.html.erb` patterns)
- **Rules**: Initial 3 rules implemented (html-img-require-alt, html-attribute-double-quotes, html-no-duplicate-ids)
- **CLI**: Basic options (`--version`, `--help`, file/directory arguments)
- **Reporter**: SimpleReporter (text output only)
- **Inline Directives**: Support for `herb:disable` and `herb:linter ignore` comments

### Post-MVP Features

Features described in this specification but not yet implemented:

- **Configuration**: Full validation, schema checking, environment variables, upward directory search
- **CLI**: `--init`, `--fix`, `--fix-unsafely`, `--format`, `--github`, `--fail-level`, `--config` options
- **Reporters**: DetailedReporter, JsonReporter, GithubReporter
- **Rules**: Complete rule set (50+ rules across ERB, HTML, and A11y categories)
- **Custom Rules**: Dynamic loading from `.herb/rules/` directory
- **Autofix**: Safe and unsafe automatic fixes
- **Advanced Features**: Parallel processing, caching, plugin system

Refer to `docs/tasks/README.md` for the detailed implementation roadmap.

## CLI Interface

### Synopsis

```bash
herb-lint [options] [files...]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `files...` | Files or directories to lint. If omitted, uses paths from configuration. |

### Options

| Option | Description |
|--------|-------------|
| `--init` | Generate a default `.herb.yml` configuration file |
| `--fix` | Apply safe automatic fixes |
| `--fix-unsafely` | Apply fixes that may change behavior (requires confirmation) |
| `--format <type>` | Output format: `detailed`, `simple`, `json` (default: `detailed`) |
| `--github` | Output GitHub Actions annotation format |
| `--fail-level <level>` | Minimum severity to cause non-zero exit: `error`, `warning`, `info`, `hint` (default: `error`) |
| `--config <path>` | Path to configuration file (default: `.herb.yml`) |
| `--ignore-disable-comments` | Ignore all inline disable comments and check all violations |
| `--version` | Show version number |
| `--help` | Show help message |

### Exit Codes

| Code | Description |
|------|-------------|
| 0 | No errors found (or only below fail-level) |
| 1 | Errors found at or above fail-level |
| 2 | Invalid configuration or runtime error |

### Examples

```bash
# Lint all files in current directory
herb-lint

# Lint specific files
herb-lint app/views/users/index.html.erb

# Lint directory
herb-lint app/views/

# Initialize configuration
herb-lint --init

# Auto-fix issues
herb-lint --fix

# JSON output for tooling
herb-lint --format json

# CI mode with GitHub annotations
herb-lint --github --fail-level warning
```

## Configuration

See [Configuration Specification](./config.md) for full details.

### Basic Linter Configuration

```yaml
linter:
  enabled: true
  include:
    - "**/*.html.erb"
    - "**/*.turbo_stream.erb"
  exclude:
    - "vendor/**"
    - "node_modules/**"
  rules:
    html-attribute-double-quotes: error
    html-img-require-alt: warn
    html-no-positive-tab-index: off
```

## Inline Directives

### Disable Rules

Disable specific rules for the next line or block:

```erb
<%# herb:disable rule-name %>
<img src="decorative.png">

<%# herb:disable rule1, rule2 %>
<div onclick="handler()">...</div>

<%# herb:disable all %>
<!-- All rules disabled for next element -->
```

### File-level Ignore

Add at the top of the file to skip linting entirely:

```erb
<%# herb:linter ignore %>
<!-- Rest of file is not linted -->
```

**Note**: Inline directives affect only the immediately following HTML/ERB node. There is no `herb:enable` directive - disabled rules remain disabled for the scope they affect.

## Output Formats

### Detailed (default)

Human-readable format with context:

```
app/views/users/index.html.erb
  12:5  error    Missing alt attribute on img tag  html-img-require-alt
  24:3  warning  Prefer double quotes for attributes  html-attribute-double-quotes

app/views/posts/show.html.erb
  8:10  error    Invalid tag nesting: <p> inside <span>  valid-tag-nesting

3 problems (2 errors, 1 warning)
```

### Simple

Compact format, one issue per line:

```
app/views/users/index.html.erb:12:5: error: Missing alt attribute on img tag [html-img-require-alt]
app/views/users/index.html.erb:24:3: warning: Prefer double quotes for attributes [html-attribute-double-quotes]
app/views/posts/show.html.erb:8:10: error: Invalid tag nesting: <p> inside <span> [valid-tag-nesting]
```

### JSON

Machine-readable format:

```json
{
  "files": [
    {
      "path": "app/views/users/index.html.erb",
      "offenses": [
        {
          "rule": "html-img-require-alt",
          "severity": "error",
          "message": "Missing alt attribute on img tag",
          "line": 12,
          "column": 5,
          "endLine": 12,
          "endColumn": 35,
          "fixable": false
        }
      ]
    }
  ],
  "summary": {
    "files": 2,
    "offenses": 3,
    "errors": 2,
    "warnings": 1,
    "fixable": 1
  }
}
```

### GitHub Actions

Annotations for GitHub Actions workflows:

```
::error file=app/views/users/index.html.erb,line=12,col=5::Missing alt attribute on img tag (html-img-require-alt)
::warning file=app/views/users/index.html.erb,line=24,col=3::Prefer double quotes for attributes (html-attribute-double-quotes)
```

## Rule Categories

### ERB Rules (13 rules)

Rules specific to ERB syntax and conventions.

| Rule | Description | Fixable |
|------|-------------|---------|
| `erb-comment-syntax` | Enforce ERB comment style | Yes |
| `erb-tag-spacing` | Consistent spacing inside ERB tags | Yes |
| `erb-no-trailing-whitespace` | No trailing whitespace in ERB output | Yes |
| `erb-output-safety` | Warn about potentially unsafe output | No |
| `erb-strict-locals` | Validate strict_locals magic comment | No |
| `erb-no-multiline-output` | Avoid multiline expressions in output tags | No |
| `erb-indent` | Consistent indentation in ERB blocks | Yes |
| `erb-no-space-before-close` | No space before closing `%>` | Yes |
| `erb-space-after-open` | Space after opening `<%` | Yes |
| `erb-no-do-end` | Prefer `{ }` over `do end` in single-line ERB | Yes |
| `erb-simple-output` | Simplify unnecessary `.to_s` calls | Yes |
| `erb-no-inline-styles` | Discourage inline styles | No |
| `erb-consistent-quotes` | Consistent quote style in ERB | Yes |

### HTML Rules (25+ rules)

General HTML validation and best practices.

| Rule | Description | Fixable |
|------|-------------|---------|
| `html-attribute-double-quotes` | Require quotes around attribute values | Yes |
| `attribute-spacing` | No spaces around `=` in attributes | Yes |
| `no-duplicate-attributes` | Disallow duplicate attributes | No |
| `no-duplicate-id` | Disallow duplicate id values | No |
| `valid-tag-nesting` | Validate tag nesting rules | No |
| `void-element-style` | Consistent self-closing style for void elements | Yes |
| `lowercase-tags` | Enforce lowercase tag names | Yes |
| `lowercase-attributes` | Enforce lowercase attribute names | Yes |
| `no-obsolete-tags` | Disallow obsolete HTML tags | No |
| `html-no-positive-tab-index` | Disallow positive tabindex values | No |
| `required-attributes` | Require mandatory attributes | No |
| `no-inline-event-handlers` | Discourage inline event handlers | No |
| `doctype` | Require DOCTYPE declaration | No |
| `html-lang` | Require lang attribute on html element | No |
| `meta-charset` | Require charset meta tag | No |
| `meta-viewport` | Require viewport meta tag | No |
| `title` | Require title element | No |
| `no-autofocus` | Discourage autofocus attribute | No |
| `no-target-blank` | Warn about target="_blank" without rel | Yes |
| `button-type` | Require type attribute on buttons | Yes |
| `form-action` | Require action attribute on forms | No |
| `input-name` | Require name attribute on inputs | No |
| `label-for` | Require for attribute on labels | No |
| `script-type` | Omit type for JavaScript | Yes |
| `style-type` | Omit type for CSS | Yes |

### Accessibility Rules (15+ rules)

ARIA and accessibility validation.

| Rule | Description | Fixable |
|------|-------------|---------|
| `html-img-require-alt` | Require alt attribute on img tags | No |
| `aria-valid-attr` | Valid ARIA attributes | No |
| `aria-valid-attr-value` | Valid ARIA attribute values | No |
| `aria-role` | Valid ARIA roles | No |
| `aria-labelledby` | Validate aria-labelledby references | No |
| `aria-describedby` | Validate aria-describedby references | No |
| `role-supports-aria` | ARIA attributes supported by role | No |
| `no-redundant-role` | Avoid redundant roles | Yes |
| `heading-order` | Headings should not skip levels | No |
| `iframe-has-title` | Require title on iframes | No |
| `interactive-supports-focus` | Interactive elements must be focusable | No |
| `click-events-have-key-events` | Click handlers need keyboard handlers | No |
| `mouse-events-have-key-events` | Mouse events need keyboard events | No |
| `no-access-key` | Avoid accesskey attribute | No |
| `scope-valid` | Valid scope attribute on th elements | No |

## Severity Levels

| Level | Description | Default Behavior |
|-------|-------------|------------------|
| `error` | Must be fixed before deployment | Causes non-zero exit |
| `warn` / `warning` | Should be fixed but not blocking | Reported but doesn't fail |
| `info` | Informational suggestions | Reported only |
| `hint` | Low-priority suggestions | Reported only |
| `off` | Rule disabled | Not checked |

## Custom Rules

### Directory

Custom rules are loaded from `.herb/rules/*.rb`.

### Base Class

```ruby
module Herb
  module Lint
    module Rules
      class Base
        # @return [String] Rule identifier (kebab-case)
        def self.rule_name
          raise NotImplementedError
        end

        # @return [Symbol] Default severity (:error, :warning, :info, :hint)
        def self.default_severity
          :warning
        end

        # @return [String] Rule description
        def self.description
          raise NotImplementedError
        end

        # @return [Boolean] Whether the rule supports auto-fix
        def self.fixable?
          false
        end

        # @param node [Herb::AST::Node] AST node to check
        # @param context [Herb::Lint::Context] Linting context
        # @return [Array<Herb::Lint::Offense>] Detected offenses
        def check(node, context)
          raise NotImplementedError
        end

        # @param node [Herb::AST::Node] AST node to fix
        # @param context [Herb::Lint::Context] Linting context
        # @return [String, nil] Fixed content or nil if not fixable
        def fix(node, context)
          nil
        end
      end
    end
  end
end
```

### Example Custom Rule

```ruby
# .herb/rules/no_inline_styles.rb
module Herb
  module Lint
    module Rules
      class NoInlineStyles < Base
        def self.rule_name
          "no-inline-styles"
        end

        def self.description
          "Disallow inline style attributes"
        end

        def check(node, context)
          return [] unless node.type == :element

          offenses = []
          if node.attributes["style"]
            offenses << Offense.new(
              rule: self.class.rule_name,
              message: "Avoid inline styles, use CSS classes instead",
              node: node,
              severity: context.severity_for(self.class.rule_name)
            )
          end
          offenses
        end
      end
    end
  end
end
```

### Visitor Pattern

Rules can implement visitor methods for specific node types:

```ruby
class MyRule < Base
  # Called for each element node
  def visit_element(node, context)
    # Check element
  end

  # Called for each attribute
  def visit_attribute(name, value, node, context)
    # Check attribute
  end

  # Called for each ERB output tag
  def visit_erb_output(node, context)
    # Check ERB output
  end
end
```

## Internal Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                         CLI                             │
│  (argument parsing, file discovery, output formatting)  │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                       Runner                            │
│  (orchestrates linting, manages concurrency)            │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                       Config                            │
│  (loads .herb.yml, resolves rule settings)              │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                   Rule Registry                         │
│  (loads built-in and custom rules)                      │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                        Rules                            │
│  (individual rule implementations)                      │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                      Reporter                           │
│  (formats output: detailed, simple, json, github)       │
└─────────────────────────────────────────────────────────┘
```

### Processing Flow

1. CLI parses arguments and options
2. Config loads `.herb.yml` and resolves file patterns
3. Runner discovers files matching include/exclude patterns
4. For each file:
   a. Parse with `herb` gem to get AST
   b. Check for file-level ignore directive
   c. Apply each enabled rule to AST
   d. Collect offenses, respecting inline disables
   e. If `--fix`, apply fixes and write back
5. Reporter formats and outputs results
6. Return appropriate exit code

## Related Documents

- [Configuration Specification](./config.md)
- [Project Overview](./overview.md)
