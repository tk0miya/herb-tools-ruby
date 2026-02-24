# herb-lint Specification

Static analysis tool for ERB templates.

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
| `--no-custom-rules` | Skip loading custom rules from `linter.custom_rules` |
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

Machine-readable format matching TypeScript herb linter.

#### Output Structure

The JSON output follows this schema:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `offenses` | Array | Yes | List of all detected offenses |
| `summary` | Object | Yes | Aggregate statistics about the linting run |
| `timing` | Number \| null | Yes | Execution time in milliseconds (currently always `null`) |
| `completed` | Boolean | Yes | Whether the linting process completed successfully |
| `clean` | Boolean | Yes | `true` if no offenses were found, `false` otherwise |
| `message` | String \| null | Yes | Optional message (e.g., error description if not completed) |

#### Offense Object

Each offense in the `offenses` array has the following structure:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `filename` | String | Yes | Path to the file containing the offense |
| `message` | String | Yes | Human-readable description of the issue |
| `location` | Object | Yes | Source location of the offense |
| `location.start` | Object | Yes | Starting position of the offense |
| `location.start.line` | Integer | Yes | Starting line number (1-indexed) |
| `location.start.column` | Integer | Yes | Starting column number (1-indexed) |
| `location.end` | Object | Yes | Ending position of the offense |
| `location.end.line` | Integer | Yes | Ending line number (1-indexed) |
| `location.end.column` | Integer | Yes | Ending column number (1-indexed) |
| `severity` | String | Yes | Severity level: `"error"`, `"warning"`, `"info"`, or `"hint"` |
| `code` | String | Yes | Rule identifier (e.g., `"html-img-require-alt"`) |
| `source` | String | Yes | Tool name (always `"Herb Linter"`) |

#### Summary Object

The `summary` object provides aggregate statistics:

| Field | Type | Description |
|-------|------|-------------|
| `filesChecked` | Integer | Total number of files that were linted |
| `filesWithOffenses` | Integer | Number of files containing at least one offense |
| `totalErrors` | Integer | Count of offenses with `error` severity |
| `totalWarnings` | Integer | Count of offenses with `warning` severity |
| `totalInfo` | Integer | Count of offenses with `info` severity |
| `totalHints` | Integer | Count of offenses with `hint` severity |
| `totalIgnored` | Integer | Count of offenses suppressed by `herb:disable` directives |
| `totalOffenses` | Integer | Total count of active offenses (sum of all severity levels, excluding ignored) |
| `ruleCount` | Integer | Number of rules that were active during linting |

#### Example

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

The Ruby implementation provides **50 built-in rules** organized into 5 categories:

- **ERB Rules** (13 rules): ERB syntax, tag formatting, and strict locals validation
- **HTML Rules** (30+ rules): HTML validation, attribute formatting, tag nesting, and accessibility
- **SVG Rules** (1 rule): SVG element validation
- **Herb Directive Rules** (6 rules): `herb:disable` comment syntax validation
- **Parser Rules** (1 rule): ERB parsing error detection

**Key Highlights:**
- Most rules use `error` severity by default (aligned with TypeScript implementation)
- 13 rules support safe autofix
- 5 rules are disabled by default (opt-in): `erb-strict-locals-required`, `html-navigation-has-label`, `html-no-block-inside-inline`, `html-no-space-in-tag`, `html-no-title-attribute`

**For a complete list of all rules with detailed descriptions, severity levels, and autofix support, see:**
- [Rule Design Document](../design/herb-lint-rules.md) - Complete rule reference with metadata
- Run `herb-lint --help` for available rules

## Severity Levels

| Level | Description | Default Behavior |
|-------|-------------|------------------|
| `error` | Must be fixed before deployment | Causes non-zero exit |
| `warn` / `warning` | Should be fixed but not blocking | Reported but doesn't fail |
| `info` | Informational suggestions | Reported only |
| `hint` | Low-priority suggestions | Reported only |
| `off` | Rule disabled | Not checked |

## Custom Rules

> **Note:** The TypeScript reference implementation uses `.herb/rules/*.mjs`, auto-discovering rule files from a fixed directory. The Ruby implementation replaces this with an explicit require-based system: users list names in `linter.custom_rules`, and each is passed to `Kernel#require`. This removes the fixed-directory constraint, allowing rules to come from gems, local files, or any path on `$LOAD_PATH`.

### Configuration

Custom rules are specified in `.herb.yml` under the `linter.custom_rules` key:

```yaml
linter:
  custom_rules:
    - herb-lint-rails
    - herb-lint-i18n
```

### How It Works

1. The `Runner` calls `RuleRegistry#load_custom_rules` at startup
2. Each name is passed to `Kernel#require`
3. Newly defined subclasses of `VisitorRule` or `SourceRule` are automatically discovered via ObjectSpace and registered in the `RuleRegistry`
4. Custom rules participate in linting alongside built-in rules

### Writing Custom Rules

Any Ruby file or gem that defines subclasses of `Herb::Lint::Rules::VisitorRule` or `SourceRule` works as a custom rule provider. No explicit registration is needed—rules are auto-discovered after `require` via ObjectSpace.

#### Example: gem-based custom rules

```ruby
# lib/herb_lint_rails.rb
require "herb/lint"

module HerbLintRails
  class PreferTurboFrame < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "rails/prefer-turbo-frame"
    def self.description = "Prefer <turbo-frame> over manual Turbo Frame patterns"
    def self.safe_autofixable? = false
    def self.unsafe_autofixable? = false

    def visit_html_element(node)
      # Rule implementation using visitor pattern
      super
    end
  end
end
```

No explicit registration is needed. The rule class is automatically discovered and registered after `require`.

#### Example: local file custom rules

```ruby
# lib/my_rules/no_data_attributes.rb
module MyRules
  class NoDataAttributes < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "my/no-data-attributes"
    def self.description = "Disallow data-* attributes"
    def self.safe_autofixable? = false
    def self.unsafe_autofixable? = false
  end
end
```

```yaml
# .herb.yml — use a local file path (relative or absolute)
linter:
  custom_rules:
    - ./lib/my_rules/no_data_attributes
```

### Configuring Custom Rules

Custom rules are configured the same way as built-in rules:

```yaml
linter:
  custom_rules:
    - herb-lint-rails
  rules:
    rails/prefer-turbo-frame:
      severity: warning
      enabled: true
```

### Disabling Custom Rules

Use `--no-custom-rules` to skip loading from `linter.custom_rules`:

```bash
herb-lint --no-custom-rules app/views
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
