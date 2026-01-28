# herb-lint

Ruby implementation of ERB template linter.

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

### Options

| Option | Description |
|--------|-------------|
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
    a11y/alt-text:
      severity: error
    html/attribute-quotes:
      severity: warning
    html/no-duplicate-id:
      severity: error
```

### Rule Severity

Each rule can be configured with a severity level:

- `error`: Causes herb-lint to exit with code 1
- `warning`: Reports the issue but doesn't affect exit code

## Available Rules

### a11y/alt-text

Requires `alt` attribute on `<img>` tags.

Images must have an alt attribute to provide a text alternative for screen readers and when images fail to load.

**Default severity:** error

**Good:**
```html
<img src="photo.jpg" alt="A sunset over the ocean">
<img src="decorative.png" alt="">
```

**Bad:**
```html
<img src="photo.jpg">
```

### html/attribute-quotes

Requires attribute values to be quoted.

Unquoted attribute values are valid HTML5, but quoting them improves readability and prevents issues with special characters.

**Default severity:** warning

**Good:**
```html
<div class="container">
<input type='text'>
<input disabled>
```

**Bad:**
```html
<div class=container>
<input type=text>
```

### html/no-duplicate-id

Disallows duplicate `id` attribute values.

The `id` attribute must be unique within a document. Duplicate ids cause accessibility issues and break JavaScript functionality that relies on `getElementById`.

**Default severity:** error

**Good:**
```html
<div id="header">...</div>
<div id="footer">...</div>
```

**Bad:**
```html
<div id="content">...</div>
<div id="content">...</div>
```

## MVP Limitations

This is an MVP (Minimum Viable Product) release with the following limitations:

**Supported:**
- Basic `.herb.yml` configuration
- File discovery with include/exclude patterns
- 3 built-in rules
- Text output format

**Not Yet Supported:**
- Custom rule loading
- Inline directives (`# herb:disable`)
- Multiple output formats (JSON, GitHub Actions)
- Auto-fix (`--fix` option)
- Environment variable support
- Parallel processing

## License

MIT

## Contributing

Bug reports and pull requests are welcome on GitHub.
