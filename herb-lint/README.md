# herb-lint

Ruby implementation of ERB template linter, providing CLI compatibility with the TypeScript `@herb-tools/linter`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'herb-lint'
```

Then execute:

```bash
bundle install
```

## Usage

### Basic Usage

```bash
# Lint all ERB files in current directory
herb-lint

# Lint specific directory
herb-lint app/views

# Lint specific files
herb-lint app/views/users/*.html.erb
```

### Autofix

```bash
# Apply safe automatic fixes
herb-lint --fix

# Apply fixes that may change behavior
herb-lint --fix-unsafely
```

### Options

| Option | Description |
|--------|-------------|
| `--fix` | Apply safe automatic fixes |
| `--fix-unsafely` | Apply fixes that may change behavior |
| `--format <type>` | Output format: `detailed`, `simple`, `json` |
| `--github` | Output GitHub Actions annotation format |
| `--fail-level <level>` | Minimum severity to cause non-zero exit |
| `--ignore-disable-comments` | Ignore all inline disable comments |
| `-c, --config-file <path>` | Path to configuration file |
| `--version` | Show version |
| `--help` | Show help message |

### Exit Codes

| Code | Description |
|------|-------------|
| 0 | No offenses found |
| 1 | Offenses found |
| 2 | Runtime error (configuration error, file I/O error, etc.) |

## Configuration

Create `.herb.yml` in your project root:

```yaml
linter:
  # Files to lint (glob patterns)
  include:
    - "**/*.html.erb"

  # Files to exclude (glob patterns)
  exclude:
    - "vendor/**/*"
    - "node_modules/**/*"
    - "tmp/**/*"

  # Rule configuration
  rules:
    html-img-require-alt:
      severity: error
    html-attribute-double-quotes:
      severity: warning
    html-no-duplicate-ids:
      severity: error
```

### Rule Severity

Each rule can be configured with a severity level:

- `error`: Causes herb-lint to exit with code 1
- `warning`: Reports the issue but doesn't affect exit code

## Inline Directives

### Disable Rules

```erb
<%# herb:disable rule-name %>
<img src="decorative.png">

<%# herb:disable rule1, rule2 %>
<div>...</div>

<%# herb:disable all %>
<!-- All rules disabled for next element -->
```

### File-level Ignore

```erb
<%# herb:linter ignore %>
<!-- Rest of file is not linted -->
```

## Available Rules (52 rules)

### ERB Rules (13 rules)

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
| `erb-strict-locals-required` | error | No | **No** |

### HTML Rules (31 rules)

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
| `html-navigation-has-label` | error | No | **No** |
| `html-no-aria-hidden-on-focusable` | error | No | Yes |
| `html-no-block-inside-inline` | error | No | **No** |
| `html-no-duplicate-attributes` | error | No | Yes |
| `html-no-duplicate-ids` | error | No | Yes |
| `html-no-duplicate-meta-names` | error | No | Yes |
| `html-no-empty-attributes` | warning | No | Yes |
| `html-no-empty-headings` | error | No | Yes |
| `html-no-nested-links` | error | No | Yes |
| `html-no-positive-tab-index` | warning | No | Yes |
| `html-no-self-closing` | error | Yes | Yes |
| `html-no-space-in-tag` | warning | No | **No** |
| `html-no-title-attribute` | error | No | **No** |
| `html-no-underscores-in-attribute-names` | warning | No | Yes |
| `html-tag-name-lowercase` | error | Yes | Yes |

### HERB Directive Rules (6 rules)

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

### Rules Disabled by Default

The following 5 rules are disabled by default and must be explicitly enabled in `.herb.yml`:

- `erb-strict-locals-required` — Opt-in Rails feature
- `html-navigation-has-label` — May have false positives
- `html-no-block-inside-inline` — Complex nesting rules
- `html-no-space-in-tag` — Controversial rule
- `html-no-title-attribute` — Controversial accessibility rule

Enable them in your configuration:

```yaml
linter:
  rules:
    erb-strict-locals-required:
      severity: error
```

## License

MIT

## Contributing

Bug reports and pull requests are welcome on GitHub.
