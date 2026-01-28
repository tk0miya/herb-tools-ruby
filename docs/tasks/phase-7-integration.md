# Phase 7: Integration Tests & Documentation

## Overview

Create end-to-end integration tests and prepare documentation. This completes the MVP.

**Dependencies:** Phase 6 (Reporter & CLI) must be completed

**Task count:** 3

---

## Task 7.1: Create Integration Tests

### Implementation

#### Create Fixtures

- [x] Create `spec/fixtures/templates/` directory
- [x] Create test `.html.erb` files
  - [x] `valid.html.erb` - Template with no offenses
  - [x] `missing_alt.html.erb` - Template with missing alt attributes
  - [x] `unquoted_attributes.html.erb` - Template with unquoted attributes
  - [x] `mixed_issues.html.erb` - Template with multiple issues
  - [x] `parse_error.html.erb` - Template with parse error (invalid ERB syntax)

#### Create Integration Tests

- [x] Create `spec/integration/linting_spec.rb`
  - [x] End-to-end integration tests
    - [x] Config loading
    - [x] File discovery and processing by Runner
    - [x] Output by Reporter
    - [x] Result verification
  - [x] Tests for each fixture
    - [x] valid.html.erb → 0 offenses
    - [x] missing_alt.html.erb → offense detected
    - [x] unquoted_attributes.html.erb → offense detected
    - [x] mixed_issues.html.erb → multiple offenses detected
    - [x] parse_error.html.erb → parse error detected

#### CLI Integration Tests

- [x] Create `spec/integration/cli_spec.rb`
  - [x] Test CLI command execution
  - [x] Verify exit codes
  - [x] Verify output format

### Fixture Examples

**valid.html.erb**
```erb
<div class="container">
  <h1>Welcome</h1>
  <img src="logo.png" alt="Company Logo">
  <p>Hello <%= user.name %></p>
</div>
```

**missing_alt.html.erb**
```erb
<div class="container">
  <img src="photo.jpg">
</div>
```

**unquoted_attributes.html.erb**
```erb
<div class=container>
  <input type=text>
</div>
```

**mixed_issues.html.erb**
```erb
<div class=container>
  <img src="photo.jpg">
  <input type=text name=email>
</div>
```

**parse_error.html.erb**
```erb
<div>
  <%= undefined method call
</div>
```

### Verification

```bash
bundle exec rspec spec/integration/linting_spec.rb
bundle exec rspec spec/integration/cli_spec.rb
```

**Expected result:** All tests pass

---

## Task 7.2: Create README

### Implementation

- [ ] Create `herb-lint/README.md`
  - [ ] Project overview
  - [ ] Installation instructions
    - [ ] Adding to Gemfile
    - [ ] `bundle install`
  - [ ] Basic usage
    - [ ] CLI usage examples
    - [ ] Option list
  - [ ] `.herb.yml` configuration examples
    - [ ] Basic configuration
    - [ ] Rule configuration
  - [ ] Clearly document MVP limitations
    - [ ] Supported features
    - [ ] Unsupported features (differences from full spec)
  - [ ] List of available rules
    - [ ] `html/alt-text`
    - [ ] `html/attribute-quotes`
  - [ ] License
  - [ ] Contributing

### README Structure Example

```markdown
# herb-lint

Ruby implementation of ERB template linter.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'herb-lint'
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

- `--version`: Show version
- `--help`: Show help

## Configuration

Create `.herb.yml` in your project root:

```yaml
linter:
  include:
    - "**/*.html.erb"
  exclude:
    - "vendor/**/*"
  rules:
    html/alt-text:
      severity: error
    html/attribute-quotes:
      severity: warning
```

## Available Rules

### html/alt-text

Ensures all `<img>` tags have an `alt` attribute.

### html/attribute-quotes

Ensures all attribute values are quoted.

## MVP Limitations

This is an MVP (Minimum Viable Product) release with the following limitations:

**Supported:**
- Basic `.herb.yml` configuration
- Simple file discovery
- 2 built-in rules
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
```

### Verification

- [ ] Review README.md content
- [ ] Test documented usage examples to verify they work

---

## Task 7.3: Create Sample Configuration File

### Implementation

- [ ] Create `.herb.yml.sample` in project root
  - [ ] Example rule configuration usable in MVP
  - [ ] Add explanations as comments for each item
  - [ ] Provide practical configuration examples

### Sample Contents

```yaml
# herb-lint configuration file
# Save this file as .herb.yml in your project root

linter:
  # Files to lint (glob patterns)
  include:
    - "**/*.html.erb"

  # Files to exclude (glob patterns)
  exclude:
    - "vendor/**/*"
    - "node_modules/**/*"
    - "tmp/**/*"

  # Linting rules configuration
  rules:
    # Enforce alt attributes on img tags
    html/alt-text:
      severity: error  # Options: error, warning

    # Enforce quoted attribute values
    html/attribute-quotes:
      severity: warning  # Options: error, warning
```

### Verification

```bash
# Copy sample configuration file
cp .herb.yml.sample .herb.yml

# Execute lint using configuration
bundle exec exe/herb-lint
```

**Expected result:** Configuration file is loaded correctly and lint executes

---

## Phase 7 Completion Criteria

- [ ] All tasks (7.1–7.3) completed
- [ ] All integration tests pass
- [ ] README.md is complete and accurate
- [ ] Sample configuration file is verified to work
- [ ] Overall documentation is complete

---

## MVP Complete!

After Phase 7 is complete, **herb-tools-ruby MVP** is finished!

### Final Verification Checklist

- [ ] 3 gems (herb-config, herb-core, herb-lint) can be built
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Can lint actual ERB files with `herb-lint` command
- [ ] 2 or more rules work
- [ ] Can load configuration from configuration file (.herb.yml)
- [ ] README.md is complete

### Next Steps (Post-MVP)

After MVP is complete, consider the following enhancements:

1. Implement additional rules
2. Custom rule loading functionality
3. Inline directive support
4. Multiple Reporter implementations (JSON, GitHub Actions, etc.)
5. `--fix` option (auto-fix)
6. herb-format gem implementation

Congratulations!
