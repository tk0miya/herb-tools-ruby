# herb-config Design Document

Design document for the configuration file management gem.

## Overview

herb-config is a shared gem responsible for loading, validating, and managing `.herb.yml` configuration files. It provides a common configuration layer used by both herb-lint and herb-format gems.

## Directory Structure

```
herb-config/
├── lib/
│   └── herb/
│       └── config/
│           ├── version.rb
│           ├── loader.rb
│           ├── validator.rb
│           ├── schema.rb
│           ├── defaults.rb
│           ├── linter_config.rb
│           ├── formatter_config.rb
│           └── errors.rb
├── spec/
│   └── herb/
│       └── config/
│           ├── loader_spec.rb
│           ├── validator_spec.rb
│           ├── schema_spec.rb
│           ├── linter_config_spec.rb
│           └── formatter_config_spec.rb
├── herb-config.gemspec
└── Gemfile
```

## Class Design

### Module Structure

```
Herb::Config
├── Loader           # Configuration file search and loading
├── Validator        # Configuration validation
├── Schema           # Schema definition
├── Defaults         # Default values
├── LinterConfig     # Linter-specific configuration
├── FormatterConfig  # Formatter-specific configuration
└── Errors           # Custom exceptions
    ├── Error
    ├── FileNotFoundError
    ├── ParseError
    └── ValidationError
```

## Component Details

### Herb::Config::Loader

**Interface:** See [`sig/herb/config/loader.rbs`](../../herb-config/sig/herb/config/loader.rbs)

**Key Responsibilities:**
- Search for configuration files using multiple strategies (explicit path, environment variable, directory traversal)
- Parse YAML configuration files safely
- Merge user configuration with default values
- Handle file not found and parse errors gracefully

**Configuration Search Order:**
1. Explicit path parameter (raises error if not found)
2. Upward directory traversal from working directory
3. Returns default configuration if no file found

**Note:** This matches the TypeScript reference implementation. Environment variables
(HERB_CONFIG, HERB_NO_CONFIG) and XDG Base Directory support are NOT implemented
to maintain cross-platform compatibility.

### Herb::Config::Validator

**Interface:** See [`sig/herb/config/validator.rbs`](../../herb-config/sig/herb/config/validator.rbs)

**Key Responsibilities:**
- Validate configuration against JSON Schema (schema.json)
- Check rule names against known rules list (optional, warning only)
- Format validation error messages
- Match TypeScript original Zod schema exactly

**Implementation:**
- Uses `json-schema` gem (~> 6.0) for declarative validation
- Schema file: `lib/herb/config/schema.json`
- Validates structure only by default; rule name validation is optional

**Validation Rules:**
- **Structure validation**: Enforced by JSON Schema (Draft 6)
- **Type validation**: boolean, integer, string, array, object
- **Severity levels**: `error`, `warning`, `info`, `hint` (4 levels only)
- **Rule format**: Object form only `{ severity: "error", enabled: true, ... }`

### Herb::Config Schema (schema.json)

JSON Schema file defining the structure and constraints of valid configuration.

**Location:** `lib/herb/config/schema.json`

**Key Features:**
- JSON Schema Draft 6 format
- Matches TypeScript original Zod schema exactly
- Declarative validation (no Ruby code needed)
- Used by `json-schema` gem for validation

**Schema Sections:**

```json
{
  "$schema": "http://json-schema.org/draft-06/schema#",
  "type": "object",
  "properties": {
    "version": { "type": "string" },
    "files": { /* File patterns configuration */ },
    "linter": { /* Linter configuration */ },
    "formatter": { /* Formatter configuration */ }
  }
}
```

**Severity Enum:**
- `error`, `warning`, `info`, `hint` (4 levels only)
- No aliases, no "off" severity
- To disable: use `enabled: false`

**Rule Configuration:**
- Object form only (no string shorthand)
- Properties: `enabled`, `severity`, `include`, `only`, `exclude`

### Herb::Config::Defaults

**Interface:** See [`sig/herb/config/defaults.rbs`](../../herb-config/sig/herb/config/defaults.rbs)

**Key Responsibilities:**
- Define default include/exclude patterns for ERB files
- Provide complete default configuration structure
- Merge user configuration with defaults (user values override defaults)

**Merge Behavior:**
- Deep merge strategy: nested hashes are merged recursively
- User values override default values at all levels
- Arrays are replaced entirely (not merged element-wise)

### Herb::Config::LinterConfig

**Interface:** See [`sig/herb/config/linter_config.rbs`](../../herb-config/sig/herb/config/linter_config.rbs)

**Key Responsibilities:**
- Extract linter section from complete configuration
- Provide accessor methods for linter settings
- Handle rule-specific configuration (enabled status, severity, options)
- Provide `custom_rules` (Array[String]): list of require names for custom rule loading (default: `[]`)
- Support both string and symbol keys for rule lookup

**Rule Configuration Format:**
- Object form only: `"html-img-require-alt": { severity: "error", enabled: true }`
- No string shorthand support in schema.json
- LinterConfig class supports both for backwards compatibility
- Default: Rules not specified use rule's default severity

### Herb::Config::FormatterConfig

**Interface:** See [`sig/herb/config/formatter_config.rbs`](../../herb-config/sig/herb/config/formatter_config.rbs)

**Key Responsibilities:**
- Extract formatter section from complete configuration
- Provide accessor methods for formatter settings
- Handle rewriter configuration (pre and post rewriters)

### Herb::Config::Errors

Custom exception hierarchy for configuration errors.

**Exception Classes:**

```rbs
module Herb
  module Config
    module Errors
      # Base error for all configuration errors
      class Error < StandardError
      end

      # Raised when explicit config file path is not found
      class FileNotFoundError < Error
      end

      # Raised when YAML file has syntax errors or can't be parsed
      class ParseError < Error
      end

      # Raised when configuration structure or values are invalid
      class ValidationError < Error
      end
    end
  end
end
```

**When Each Error is Raised:**
- `FileNotFoundError`: Explicit path provided but file doesn't exist
- `ParseError`: YAML file has syntax errors or can't be parsed
- `ValidationError`: Configuration structure or values are invalid

## Public API

### Usage Patterns

**Load and validate configuration:**

```ruby
require "herb/config"

# Automatic configuration search
config = Herb::Config::Loader.load

# Explicit path
config = Herb::Config::Loader.load(path: "/path/to/.herb.yml")

# Validate configuration
validator = Herb::Config::Validator.new(config)
validator.validate!  # Raises ValidationError if invalid
```

**Access linter configuration:**

```ruby
linter = Herb::Config::LinterConfig.new(config)
linter.include_patterns            # => ["**/*.html.erb", ...]
linter.enabled_rule?("html-img-require-alt")   # => true
linter.rule_severity("html-img-require-alt")   # => "error"
```

**Access formatter configuration:**

```ruby
formatter = Herb::Config::FormatterConfig.new(config)
formatter.enabled?                 # => true
formatter.indent_width             # => 2
formatter.max_line_length          # => 80
formatter.pre_rewriters            # => []
formatter.post_rewriters           # => []
```

## Testing Strategy

### Test Coverage Areas

**Herb::Config::Loader**
- Configuration file search (explicit path, upward traversal)
- YAML parsing and error handling
- Default configuration fallback
- File not found error scenarios

**Herb::Config::Validator**
- Type validation (boolean, integer, array, hash)
- Glob pattern validation
- Rule name validation against known rules
- Severity level validation
- Error message formatting

**Herb::Config::Schema**
- Severity normalization
- Alias handling

**Herb::Config::Defaults**
- Default value provision
- Deep merge behavior
- Array replacement vs hash merging

**Herb::Config::LinterConfig**
- Rule enabled/disabled status
- Severity extraction (string vs hash format)
- Rule options extraction
- Include/exclude pattern access

**Herb::Config::FormatterConfig**
- Configuration value access
- Rewriter list extraction
- Default value fallback

## Advanced Configuration Features

### Top-level Files Section

The configuration supports a top-level `files` section for specifying file patterns that apply to both linter and formatter. This provides a convenient way to set project-wide file patterns.

**Configuration Example:**
```yaml
files:
  include:
    - '**/*.xml.erb'
    - 'custom/**/*.html'
  exclude:
    - 'vendor/**/*'
    - 'node_modules/**/*'

linter:
  include:
    - '**/*.html.erb'  # Merged with files.include (additive)
  exclude:
    - 'tmp/**/*'       # Overrides files.exclude (precedence)
```

**Pattern Merge Behavior:**
- **`include` patterns**: ADDITIVE - Both `files.include` and `linter.include` are merged together
- **`exclude` patterns**: OVERRIDE - `linter.exclude` takes precedence; `files.exclude` is used only as fallback

This is implemented in `LinterConfig#include_patterns` and `LinterConfig#exclude_patterns`.

### Fail Level Configuration

The `linter.failLevel` setting controls CI/CD exit code behavior by specifying which severity levels should cause non-zero exit codes.

**Configuration Example:**
```yaml
linter:
  failLevel: warning  # Exit with error on warnings and errors
  rules:
    html-alt-text: error
    html-attribute-quotes: warning  # This will cause exit code 1
    html-deprecated-tags: info      # This will NOT cause exit code 1
```

**Valid values:** `error`, `warning`, `info`, `hint` (default: `error`)

This is implemented in `LinterConfig#fail_level`.

### Per-Rule File Patterns

Rules can have their own `include`, `exclude`, and `only` patterns for fine-grained control over which files they apply to.

**Configuration Example:**
```yaml
linter:
  include:
    - '**/*.html.erb'
  rules:
    html-alt-text:
      severity: error
      only:
        - 'app/views/**/*.html.erb'  # Only apply to app/views

    html-deprecated-tags:
      severity: warning
      include:
        - '**/*.xml.erb'  # Also check XML templates
      exclude:
        - 'legacy/**/*'   # Skip legacy code
```

This is implemented in `LinterConfig#build_pattern_matcher`.

## Related Documentation

- [Overall Architecture](./architecture.md)
- [Requirements: Configuration](../requirements/config.md)
