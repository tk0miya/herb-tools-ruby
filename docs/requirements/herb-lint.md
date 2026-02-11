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

Features implemented after MVP:

- **CLI**: `--fix`, `--fix-unsafely`, `--format`, `--github`, `--fail-level`, `--config-file`, `--ignore-disable-comments` options
- **Reporters**: DetailedReporter, JsonReporter, GithubReporter
- **Rules**: 52 rules across ERB, HTML, HERB, SVG, and Parser categories
- **Autofix**: Safe automatic fixes (14 autofixable rules)
- **Inline Directives**: `herb:disable`, `herb:linter ignore` comments

Features not yet implemented:

- **Configuration**: Full validation, schema checking, environment variables
- **CLI**: `--init` option
- **Custom Rules**: Dynamic loading from `.herb/rules/` directory
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
| `-c, --config-file <path>` | Path to configuration file (searches upward from current directory by default) |
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

Machine-readable format matching TypeScript herb linter:

```json
{
  "offenses": [
    {
      "filename": "app/views/users/index.html.erb",
      "message": "Missing alt attribute on img tag",
      "location": {
        "start": {
          "line": 12,
          "column": 5
        },
        "end": {
          "line": 12,
          "column": 35
        }
      },
      "severity": "error",
      "code": "html-img-require-alt",
      "source": "Herb Linter"
    }
  ],
  "summary": {
    "filesChecked": 2,
    "filesWithOffenses": 1,
    "totalErrors": 2,
    "totalWarnings": 1,
    "totalInfo": 0,
    "totalHints": 0,
    "totalIgnored": 0,
    "totalOffenses": 3,
    "ruleCount": 50
  },
  "timing": null,
  "completed": true,
  "clean": false,
  "message": null
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

| Rule | Default Severity | Fixable | Enabled |
|------|------------------|---------|---------|
| `erb-comment-syntax` | error | Yes | Yes |
| `erb-no-case-node-children` | error | No | Yes |
| `erb-no-empty-tags` | error | Yes | Yes |
| `erb-no-extra-newline` | error | Yes | Yes |
| `erb-no-extra-whitespace-inside-tags` | error | Yes | Yes |
| `erb-no-output-control-flow` | error | No | Yes |
| `erb-no-silent-tag-in-attribute-name` | error | No | Yes |
| `erb-prefer-image-tag-helper` | warning | No | Yes |
| `erb-require-trailing-newline` | error | Yes | Yes |
| `erb-require-whitespace-inside-tags` | error | Yes | Yes |
| `erb-right-trim` | error | Yes | Yes |
| `erb-strict-locals-comment-syntax` | error | No | Yes |
| `erb-strict-locals-required` | error | No | No (opt-in) |

### HTML Rules (31 rules)

General HTML validation, best practices, and accessibility.

| Rule | Default Severity | Fixable | Enabled |
|------|------------------|---------|---------|
| `html-anchor-require-href` | error | No | Yes |
| `html-aria-attribute-must-be-valid` | error | No | Yes |
| `html-aria-label-is-well-formatted` | error | No | Yes |
| `html-aria-level-must-be-valid` | error | No | Yes |
| `html-aria-role-heading-requires-level` | error | No | Yes |
| `html-aria-role-must-be-valid` | error | No | Yes |
| `html-attribute-double-quotes` | warning | Yes | Yes |
| `html-attribute-equals-spacing` | error | Yes | Yes |
| `html-attribute-values-require-quotes` | error | Yes | Yes |
| `html-avoid-both-disabled-and-aria-disabled` | error | No | Yes |
| `html-body-only-elements` | error | No | Yes |
| `html-boolean-attributes-no-value` | error | Yes | Yes |
| `html-head-only-elements` | error | No | Yes |
| `html-iframe-has-title` | error | No | Yes |
| `html-img-require-alt` | error | No | Yes |
| `html-input-require-autocomplete` | error | No | Yes |
| `html-navigation-has-label` | error | No | No (opt-in) |
| `html-no-aria-hidden-on-focusable` | error | No | Yes |
| `html-no-block-inside-inline` | error | No | No (opt-in) |
| `html-no-duplicate-attributes` | error | No | Yes |
| `html-no-duplicate-ids` | error | No | Yes |
| `html-no-duplicate-meta-names` | error | No | Yes |
| `html-no-empty-attributes` | warning | No | Yes |
| `html-no-empty-headings` | error | No | Yes |
| `html-no-nested-links` | error | No | Yes |
| `html-no-positive-tab-index` | warning | No | Yes |
| `html-no-self-closing` | error | Yes | Yes |
| `html-no-space-in-tag` | warning | No | No (opt-in) |
| `html-no-title-attribute` | error | No | No (opt-in) |
| `html-no-underscores-in-attribute-names` | warning | No | Yes |
| `html-tag-name-lowercase` | error | Yes | Yes |

### HERB Directive Rules (6 rules)

Rules for validating herb directive comments.

| Rule | Default Severity | Fixable | Enabled |
|------|------------------|---------|---------|
| `herb-disable-comment-malformed` | error | No | Yes |
| `herb-disable-comment-missing-rules` | error | No | Yes |
| `herb-disable-comment-no-duplicate-rules` | warning | No | Yes |
| `herb-disable-comment-no-redundant-all` | warning | No | Yes |
| `herb-disable-comment-unnecessary` | error | No | Yes |
| `herb-disable-comment-valid-rule-name` | warning | No | Yes |

### SVG Rules (1 rule)

| Rule | Default Severity | Fixable | Enabled |
|------|------------------|---------|---------|
| `svg-tag-name-capitalization` | error | Yes | Yes |

### Parser Rules (1 rule)

| Rule | Default Severity | Fixable | Enabled |
|------|------------------|---------|---------|
| `parser-no-errors` | error | No | Yes |

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
