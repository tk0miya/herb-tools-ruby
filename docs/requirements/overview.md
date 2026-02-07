# Project Overview

## Purpose

herb-tools-ruby provides Ruby implementations of ERB template tooling that maintains full compatibility with the TypeScript-based `@herb-tools/linter` and `@herb-tools/formatter` packages.

The primary goals are:

1. **Native Ruby Integration**: Provide first-class Ruby gems that integrate seamlessly with Ruby/Rails development workflows
2. **TypeScript Compatibility**: Share configuration files (`.herb.yml`) and provide equivalent CLI interfaces
3. **Consistent Behavior**: Ensure the same rules produce the same results across both implementations

## Scope

### In Scope

- **herb-lint**: Static analysis tool for ERB templates
  - All linting rules from the TypeScript implementation
  - CLI with identical options
  - Configuration file support
  - Custom rule support
  - Multiple output formats

- **herb-format**: Formatter for ERB templates
  - All formatting rules from the TypeScript implementation
  - CLI with identical options
  - Configuration file support
  - Rewriter plugin support

### Out of Scope

- Editor plugins/extensions (VS Code, etc.)
- Language server protocol (LSP) implementation
- Real-time linting/formatting APIs
- Web-based interfaces

## Target Users

### Primary Users

1. **Ruby/Rails Developers**: Developers working with ERB templates who want native Ruby tooling
2. **CI/CD Pipelines**: Automated quality checks in continuous integration environments
3. **Teams with Mixed Stacks**: Organizations using both TypeScript and Ruby who want consistent tooling

### Use Cases

1. **Local Development**: Run linting/formatting as part of the development workflow
2. **Pre-commit Hooks**: Validate templates before committing changes
3. **CI Checks**: Enforce template quality in pull request workflows
4. **Editor Integration**: Use as a backend for editor extensions

## TypeScript Compatibility

### Configuration File (.herb.yml)

Both implementations share the same configuration file format. A project can use a single `.herb.yml` file for both TypeScript and Ruby tools.

```yaml
linter:
  enabled: true
  include:
    - "**/*.html.erb"
  exclude:
    - "vendor/**"
  rules:
    html-attribute-double-quotes: error

formatter:
  enabled: true
  indentWidth: 2
```

### CLI Interface

CLI options are designed to match the TypeScript implementation:

| TypeScript | Ruby |
|------------|------|
| `npx herb-lint --fix` | `bundle exec herb-lint --fix` |
| `npx herb-format --check` | `bundle exec herb-format --check` |

### Rule Names

Rule names are identical across implementations:

- `html-attribute-double-quotes`
- `html-img-require-alt`
- `html-no-positive-tab-index`
- etc.

### Inline Directives

Inline disable/ignore comments work the same way:

```erb
<%# herb:disable rule-name %>
<%# herb:formatter ignore %>
```

## Target Files

Both tools process the following file types:

| Extension | Description |
|-----------|-------------|
| `*.html` | HTML files |
| `*.rhtml` | Ruby HTML files |
| `*.html.erb` | ERB templates |
| `*.html+*.erb` | ERB templates with variant |
| `*.turbo_stream.erb` | Turbo Stream templates |

## Dependencies

### Runtime Dependencies

| Dependency | Purpose | Version |
|------------|---------|---------|
| `herb` | ERB parser providing AST | >= 1.0 |

The `herb` gem provides:
- ERB template parsing
- AST (Abstract Syntax Tree) generation
- Location information for error reporting

### Development Dependencies

| Dependency | Purpose |
|------------|---------|
| `rspec` | Testing framework |
| `rubocop` | Ruby style enforcement |

## Ruby Version Support

| Ruby Version | Support Status |
|--------------|----------------|
| 3.3+ | Full support |
| 3.2 | Not supported |
| < 3.2 | Not supported |

Ruby 3.3+ is required for:
- Modern pattern matching features
- Performance improvements
- Current security support

## Versioning

The project follows [Semantic Versioning](https://semver.org/):

- **Major**: Breaking changes to CLI or configuration format
- **Minor**: New rules, features, or options
- **Patch**: Bug fixes and performance improvements

Both gems maintain independent version numbers but are released together for compatibility.

## Related Documents

- [herb-lint Specification](./herb-lint.md)
- [herb-format Specification](./herb-format.md)
- [Configuration Specification](./config.md)
