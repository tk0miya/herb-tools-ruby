# herb-lint

Ruby implementation of ERB template linter, compatible with the TypeScript [@herb-tools/linter](https://github.com/marcoroth/herb) package.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'herb-lint'
```

Then execute:

```bash
bundle install
```

Or install globally:

```bash
gem install herb-lint
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

# Auto-fix issues where possible
herb-lint --fix

# Show version
herb-lint --version

# Show help
herb-lint --help
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `--fix` | Automatically fix autofixable offenses |
| `--config PATH` | Specify configuration file path (default: `.herb.yml`) |
| `--format FORMAT` | Output format: `text`, `json` (default: `text`) |
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
    - "**/*.erb"

  # Files to exclude (glob patterns)
  exclude:
    - "vendor/**/*"
    - "node_modules/**/*"
    - "tmp/**/*"

  # Rule configuration
  rules:
    # Enable/disable rules
    html-img-require-alt:
      enabled: true
      severity: error

    # Some rules are disabled by default
    erb-strict-locals-required:
      enabled: true
      severity: error

    # Configure rule-specific options
    html-attribute-double-quotes:
      severity: warning
```

### Inline Directives

Use inline comments to disable rules for specific lines:

```erb
<%# herb:disable html-img-require-alt %>
<img src="photo.jpg">

<%# herb:disable html-no-duplicate-ids, html-img-require-alt %>
<img src="photo.jpg" id="foo">
<img src="bar.jpg" id="foo">

<%# herb:disable all %>
<img src="invalid.jpg">
```

### Rule Severity

Each rule can be configured with a severity level:

- `error`: Causes herb-lint to exit with code 1 (default for most rules)
- `warning`: Reports the issue but doesn't affect exit code

### Rule Enabled Status

Most rules are enabled by default. Some rules are disabled by default because they are opt-in features or may have false positives:

- `erb-strict-locals-required` - Requires Rails strict locals
- `html-navigation-has-label` - May have false positives
- `html-no-block-inside-inline` - Complex nesting rules
- `html-no-space-in-tag` - Controversial formatting rule
- `html-no-title-attribute` - Controversial accessibility rule

## Available Rules

herb-lint provides **50 built-in rules** organized into 4 categories:

### ERB Rules (13)

Rules for ERB syntax and best practices:

- `erb-comment-syntax` - Enforce ERB comment syntax
- `erb-no-case-node-children` - Disallow case node children
- `erb-no-empty-tags` - Disallow empty ERB tags
- `erb-no-extra-newline` - Disallow extra newlines (**autofix**)
- `erb-no-extra-whitespace-inside-tags` - Disallow extra whitespace (**autofix**)
- `erb-no-output-control-flow` - Disallow output tags for control flow
- `erb-no-silent-tag-in-attribute-name` - Disallow silent tags in attribute names
- `erb-prefer-image-tag-helper` - Prefer Rails image_tag helper
- `erb-require-trailing-newline` - Require trailing newline (**autofix**)
- `erb-require-whitespace-inside-tags` - Require whitespace inside tags (**autofix**)
- `erb-right-trim` - Enforce right trim usage (**autofix**)
- `erb-strict-locals-comment-syntax` - Enforce strict locals comment syntax (**autofix**)
- `erb-strict-locals-required` - Require strict locals (disabled by default)

### HTML Rules (29)

Rules for HTML syntax, semantics, and accessibility:

- `html-anchor-require-href` - Require href on anchor tags
- `html-aria-attribute-must-be-valid` - Validate ARIA attributes
- `html-aria-label-is-well-formatted` - Validate ARIA label formatting
- `html-aria-level-must-be-valid` - Validate ARIA level values
- `html-aria-role-heading-requires-level` - Require level for heading roles
- `html-aria-role-must-be-valid` - Validate ARIA roles
- `html-attribute-double-quotes` - Enforce double quotes (**autofix**)
- `html-attribute-equals-spacing` - Disallow spacing around = (**autofix**)
- `html-attribute-values-require-quotes` - Require quotes on attribute values (**autofix**)
- `html-avoid-both-disabled-and-aria-disabled` - Avoid both disabled attributes
- `html-body-only-elements` - Enforce body-only elements (**autofix**)
- `html-boolean-attributes-no-value` - Disallow values on boolean attributes (**autofix**)
- `html-head-only-elements` - Enforce head-only elements (**autofix**)
- `html-iframe-has-title` - Require title on iframes
- `html-img-require-alt` - Require alt on images
- `html-input-require-autocomplete` - Require autocomplete on inputs
- `html-navigation-has-label` - Require labels on navigation (disabled by default)
- `html-no-aria-hidden-on-focusable` - Disallow aria-hidden on focusable elements
- `html-no-block-inside-inline` - Disallow block elements inside inline (disabled by default)
- `html-no-duplicate-attributes` - Disallow duplicate attributes
- `html-no-duplicate-ids` - Disallow duplicate IDs
- `html-no-duplicate-meta-names` - Disallow duplicate meta names
- `html-no-empty-attributes` - Disallow empty attributes
- `html-no-empty-headings` - Disallow empty headings
- `html-no-nested-links` - Disallow nested links
- `html-no-positive-tab-index` - Disallow positive tabindex
- `html-no-self-closing` - Disallow self-closing tags (**autofix**)
- `html-no-space-in-tag` - Disallow spaces in tags (disabled by default, **autofix**)
- `html-no-title-attribute` - Disallow title attribute (disabled by default)
- `html-no-underscores-in-attribute-names` - Disallow underscores in attribute names
- `html-tag-name-lowercase` - Enforce lowercase tag names (**autofix**)

### SVG Rules (1)

- `svg-tag-name-capitalization` - Enforce SVG tag name capitalization (**autofix**)

### Herb Directive Rules (6)

Rules for validating inline `herb:disable` directives:

- `herb-disable-comment-malformed` - Detect malformed disable comments
- `herb-disable-comment-missing-rules` - Require rule names
- `herb-disable-comment-no-duplicate-rules` - Disallow duplicate rule names
- `herb-disable-comment-no-redundant-all` - Disallow redundant 'all' keyword
- `herb-disable-comment-unnecessary` - Detect unnecessary disable comments
- `herb-disable-comment-valid-rule-name` - Validate rule names

### Autofix Support

Rules marked with **autofix** support automatic fixing via `herb-lint --fix`. Many rules provide safe autofixes that can automatically correct violations.

## Features

herb-lint is feature-complete and production-ready with full TypeScript implementation compatibility:

**Linting:**
- 50 built-in rules (ERB, HTML, SVG, accessibility, directive validation)
- Configurable rule severity (error, warning)
- Per-rule enabled/disabled configuration
- Pattern-based file inclusion/exclusion
- Inline directive support (`herb:disable`)

**Autofix:**
- Safe automatic fixes for many rules
- `--fix` command-line option
- Rule-level autofix configuration

**Configuration:**
- `.herb.yml` configuration files
- Rule-specific options
- Severity customization
- Include/exclude patterns

**Output Formats:**
- Text format (human-readable)
- JSON format (machine-readable)

**Integration:**
- CLI compatibility with TypeScript `@herb-tools/linter`
- Same configuration file format
- Equivalent rule behavior

## License

MIT

## Contributing

Bug reports and pull requests are welcome on GitHub.
