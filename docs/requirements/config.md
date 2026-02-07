# Configuration Specification

Complete specification for the `.herb.yml` configuration file.

## Overview

The `.herb.yml` file configures both herb-lint and herb-format. This format is shared with the TypeScript implementation, allowing projects to use a single configuration file for both ecosystems.

## File Location

Configuration is searched in the following order:

1. Path specified via `--config` option
2. `.herb.yml` in current working directory
3. `.herb.yml` in parent directories (up to project root)
4. Default configuration (if no file found)

## Complete Schema

```yaml
# Linter configuration
linter:
  # Enable or disable the linter (default: true)
  enabled: true

  # File patterns to include (glob syntax)
  include:
    - "**/*.html"
    - "**/*.rhtml"
    - "**/*.html.erb"
    - "**/*.html+*.erb"
    - "**/*.turbo_stream.erb"

  # File patterns to exclude (glob syntax)
  exclude:
    - "vendor/**"
    - "node_modules/**"
    - "tmp/**"

  # Rule configurations
  rules:
    # Rule can be set to severity level
    rule-name: error | warn | warning | info | hint | off

    # Or with additional options
    rule-name:
      severity: error
      options:
        # Rule-specific options

# Formatter configuration
formatter:
  # Enable or disable the formatter (default: true)
  enabled: true

  # Number of spaces for indentation (default: 2)
  indentWidth: 2

  # Maximum line length before wrapping (default: 80)
  maxLineLength: 80

  # File patterns to include (glob syntax)
  include:
    - "**/*.html"
    - "**/*.rhtml"
    - "**/*.html.erb"
    - "**/*.html+*.erb"
    - "**/*.turbo_stream.erb"

  # File patterns to exclude (glob syntax)
  exclude:
    - "vendor/**"
    - "node_modules/**"
    - "tmp/**"

  # Rewriter pipeline configuration
  rewriter:
    # Rewriters run before formatting
    pre: []

    # Rewriters run after formatting
    post: []
```

## Linter Configuration

### enabled

Type: `boolean`
Default: `true`

Enable or disable the linter globally.

```yaml
linter:
  enabled: false  # Disable linter entirely
```

### include

Type: `array of string` (glob patterns)
Default: `["**/*.html", "**/*.rhtml", "**/*.html.erb", "**/*.html+*.erb", "**/*.turbo_stream.erb"]`

File patterns to include in linting.

```yaml
linter:
  include:
    - "app/views/**/*.html.erb"
    - "app/components/**/*.html.erb"
```

### exclude

Type: `array of string` (glob patterns)
Default: `["vendor/**", "node_modules/**"]`

File patterns to exclude from linting.

```yaml
linter:
  exclude:
    - "vendor/**"
    - "node_modules/**"
    - "app/views/legacy/**"
```

### rules

Type: `object`
Default: All rules enabled with default severities

Configure individual rules.

#### Simple Severity

```yaml
linter:
  rules:
    html-attribute-double-quotes: error
    html-img-require-alt: warn
    html-no-positive-tab-index: off
```

#### With Options

```yaml
linter:
  rules:
    html-attribute-double-quotes:
      severity: error
      options:
        style: double  # 'single' or 'double'

    heading-order:
      severity: warn
      options:
        allowMultipleH1: false
```

#### Severity Levels

| Level | Aliases | Description |
|-------|---------|-------------|
| `error` | - | Causes non-zero exit code |
| `warn` | `warning` | Reported but doesn't fail |
| `info` | - | Informational |
| `hint` | - | Low priority |
| `off` | - | Rule disabled |

## Formatter Configuration

### enabled

Type: `boolean`
Default: `true`

Enable or disable the formatter globally.

```yaml
formatter:
  enabled: false  # Disable formatter entirely
```

### indentWidth

Type: `integer`
Default: `2`

Number of spaces for each indentation level.

```yaml
formatter:
  indentWidth: 4  # Use 4 spaces
```

### maxLineLength

Type: `integer`
Default: `80`

Maximum line length before attributes are wrapped.

```yaml
formatter:
  maxLineLength: 120  # Longer lines allowed
```

### include

Type: `array of string` (glob patterns)
Default: `["**/*.html", "**/*.rhtml", "**/*.html.erb", "**/*.html+*.erb", "**/*.turbo_stream.erb"]`

File patterns to include in formatting.

```yaml
formatter:
  include:
    - "app/views/**/*.html.erb"
```

### exclude

Type: `array of string` (glob patterns)
Default: `["vendor/**", "node_modules/**"]`

File patterns to exclude from formatting.

```yaml
formatter:
  exclude:
    - "vendor/**"
    - "app/views/emails/**"  # Preserve email formatting
```

### rewriter

Type: `object`
Default: `{ pre: [], post: [] }`

Configure rewriter plugins.

```yaml
formatter:
  rewriter:
    pre:
      - normalize-attributes
    post:
      - tailwind-class-sorter
      - sort-attributes
```

## Default Configuration

When no `.herb.yml` is found, the following defaults are used:

```yaml
linter:
  enabled: true
  include:
    - "**/*.html"
    - "**/*.rhtml"
    - "**/*.html.erb"
    - "**/*.html+*.erb"
    - "**/*.turbo_stream.erb"
  exclude:
    - "vendor/**"
    - "node_modules/**"
  rules: {}  # All rules enabled with default severities

formatter:
  enabled: true
  indentWidth: 2
  maxLineLength: 80
  include:
    - "**/*.html"
    - "**/*.rhtml"
    - "**/*.html.erb"
    - "**/*.html+*.erb"
    - "**/*.turbo_stream.erb"
  exclude:
    - "vendor/**"
    - "node_modules/**"
  rewriter:
    pre: []
    post: []
```

## Generated Configuration

Running `herb-lint --init` or `herb-format --init` generates:

```yaml
# Herb Tools Configuration
# https://github.com/marcoroth/herb

linter:
  enabled: true
  include:
    - "**/*.html.erb"
    - "**/*.turbo_stream.erb"
  exclude:
    - "vendor/**"
    - "node_modules/**"
  rules:
    # Uncomment to customize rule severity
    # attribute-quotes: error
    # alt-text: warn
    # no-positive-tabindex: off

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
    post: []
```

## Glob Pattern Syntax

The configuration uses standard glob patterns:

| Pattern | Description |
|---------|-------------|
| `*` | Match any characters except `/` |
| `**` | Match any characters including `/` |
| `?` | Match single character |
| `[abc]` | Match any character in brackets |
| `[a-z]` | Match character range |
| `{a,b}` | Match either pattern |

### Examples

```yaml
include:
  - "app/**/*.erb"           # All .erb files in app/
  - "*.html"                  # .html files in root
  - "components/**/*.html.*" # .html.erb, .html+phone.erb, etc.

exclude:
  - "**/test/**"             # Exclude test directories
  - "**/*.generated.erb"     # Exclude generated files
```

## TypeScript Compatibility

### Shared Fields

The following fields are fully compatible between Ruby and TypeScript implementations:

| Field | Notes |
|-------|-------|
| `linter.enabled` | Identical behavior |
| `linter.include` | Same glob syntax |
| `linter.exclude` | Same glob syntax |
| `linter.rules` | Same rule names |
| `formatter.enabled` | Identical behavior |
| `formatter.indentWidth` | Identical behavior |
| `formatter.maxLineLength` | Identical behavior |
| `formatter.include` | Same glob syntax |
| `formatter.exclude` | Same glob syntax |
| `formatter.rewriter.pre` | Same rewriter names |
| `formatter.rewriter.post` | Same rewriter names |

### Cross-Platform Usage

A single `.herb.yml` can be used by both implementations:

```yaml
# Works with both:
# - npx herb-lint / npx herb-format (TypeScript)
# - bundle exec herb-lint / bundle exec herb-format (Ruby)

linter:
  enabled: true
  rules:
    html-attribute-double-quotes: error

formatter:
  enabled: true
  indentWidth: 2
```

## Configuration Validation

Invalid configuration generates clear error messages:

```
Error: Invalid configuration in .herb.yml

  linter.rules.unknown-rule: Unknown rule "unknown-rule"
  formatter.indentWidth: Must be a positive integer, got "four"
  formatter.include[0]: Invalid glob pattern "["

See documentation for valid configuration options.
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `HERB_CONFIG` | Path to configuration file (overrides default search) |
| `HERB_NO_CONFIG` | If set, ignore all configuration files |

```bash
HERB_CONFIG=/path/to/.herb.yml herb-lint
HERB_NO_CONFIG=1 herb-lint  # Use defaults only
```

## Related Documents

- [herb-lint Specification](./herb-lint.md)
- [herb-format Specification](./herb-format.md)
- [Project Overview](./overview.md)
