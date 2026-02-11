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

Responsible for locating and loading `.herb.yml` configuration files from the filesystem.

**Key Responsibilities:**
- Search for configuration files using multiple strategies (explicit path, environment variable, directory traversal)
- Parse YAML configuration files safely
- Merge user configuration with default values
- Handle file not found and parse errors gracefully

**Public Interface:**

```rbs
module Herb
  module Config
    class Loader
      CONFIG_FILENAME: String

      @explicit_path: String?
      @working_dir: String

      def initialize: (?path: String?, ?working_dir: String) -> void

      # Load and return merged configuration
      # @raise [FileNotFoundError] When explicit path is not found
      # @raise [ParseError] When YAML parsing fails
      def load: () -> Hash[String, untyped]

      # Locate configuration file path
      def find_config_path: () -> String?

      private

      def load_from_file: (String path) -> Hash[String, untyped]
      def parse_yaml: (String content) -> Hash[String, untyped]
    end
  end
end
```

**Configuration Search Order:**
1. Explicit path parameter (raises error if not found)
2. `HERB_CONFIG` environment variable
3. Upward directory traversal from working directory
4. Returns default configuration if no file found

### Herb::Config::Validator

Validates configuration structure and values using JSON Schema.

**Key Responsibilities:**
- Validate configuration against JSON Schema (schema.json)
- Check rule names against known rules list (optional, warning only)
- Format validation error messages
- Match TypeScript original Zod schema exactly

**Implementation:**
- Uses `json-schema` gem (~> 6.0) for declarative validation
- Schema file: `lib/herb/config/schema.json`
- Validates structure only by default; rule name validation is optional

**Public Interface:**

```rbs
module Herb
  module Config
    class Validator
      SCHEMA_PATH: String

      @config: Hash[String, untyped]
      @errors: Array[String]?

      def initialize: (Hash[String, untyped] config) -> void

      # Check if configuration is valid
      def valid?: () -> bool

      # Validate and raise exception if invalid
      # @raise [ValidationError] With formatted error messages
      def validate!: () -> void

      # Get validation errors
      def errors: () -> Array[String]

      private

      def validate_config: () -> void
      def load_schema: () -> Hash[String, untyped]
      def format_schema_error_object: (Hash[Symbol, untyped] error) -> String
    end
  end
end
```

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

Provides default configuration values and merging behavior.

**Key Responsibilities:**
- Define default include/exclude patterns for ERB files
- Provide complete default configuration structure
- Merge user configuration with defaults (user values override defaults)

**Public Interface:**

```rbs
module Herb
  module Config
    module Defaults
      DEFAULT_INCLUDE: Array[String]

      DEFAULT_EXCLUDE: Array[String]

      def self.config: () -> Hash[String, untyped]

      def self.merge: (Hash[String, untyped] user_config) -> Hash[String, untyped]

      private

      def self.deep_merge: (Hash[String, untyped] base, Hash[String, untyped] override) -> Hash[String, untyped]
    end
  end
end
```

**Merge Behavior:**
- Deep merge strategy: nested hashes are merged recursively
- User values override default values at all levels
- Arrays are replaced entirely (not merged element-wise)

### Herb::Config::LinterConfig

Provides convenient access to linter-specific configuration.

**Key Responsibilities:**
- Extract linter section from complete configuration
- Provide accessor methods for linter settings
- Handle rule-specific configuration (enabled status, severity, options)
- Support both string and symbol keys for rule lookup

**Public Interface:**

```rbs
module Herb
  module Config
    class LinterConfig
      @config: Hash[String, untyped]
      @linter_config: Hash[String, untyped]

      def initialize: (Hash[String, untyped] config) -> void

      def enabled?: () -> bool

      # Returns file patterns to include in linting
      # Merges patterns from both 'files.include' and 'linter.include' (additive)
      def include_patterns: () -> Array[String]

      # Returns file patterns to exclude from linting
      # Uses 'linter.exclude' if present (override), otherwise 'files.exclude' (fallback)
      def exclude_patterns: () -> Array[String]

      def rules: () -> Hash[String, untyped]

      def rule_enabled?: (String rule_name) -> bool

      def rule_severity: (String rule_name, ?default: Symbol) -> Symbol

      # Returns the fail level for the linter (CI/CD exit code control)
      # Determines which severity levels cause non-zero exit codes
      # Defaults to "error" if not configured
      def fail_level: () -> String

      # Builds a PatternMatcher for rule-specific file patterns
      # Returns a matcher configured with rule's include, exclude, and only patterns
      def build_pattern_matcher: (String rule_name) -> Herb::Core::PatternMatcher

      private

      def normalize_rule_name: (String | Symbol rule_name) -> String
      def extract_severity: (String | Symbol | Hash[String, untyped] rule_config) -> Symbol
    end
  end
end
```

**Rule Configuration Format:**
- Object form only: `"html-img-require-alt": { severity: "error", enabled: true }`
- No string shorthand support in schema.json
- LinterConfig class supports both for backwards compatibility
- Default: Rules not specified use rule's default severity

### Herb::Config::FormatterConfig

Provides convenient access to formatter-specific configuration.

**Key Responsibilities:**
- Extract formatter section from complete configuration
- Provide accessor methods for formatter settings
- Handle rewriter configuration (pre and post rewriters)

**Public Interface:**

```rbs
module Herb
  module Config
    class FormatterConfig
      @config: Hash[String, untyped]
      @formatter_config: Hash[String, untyped]

      def initialize: (Hash[String, untyped] config) -> void

      def enabled?: () -> bool

      def indent_width: () -> Integer

      def max_line_length: () -> Integer

      def include_patterns: () -> Array[String]

      def exclude_patterns: () -> Array[String]

      def pre_rewriters: () -> Array[String]

      def post_rewriters: () -> Array[String]

      private

      def rewriter_config: () -> Hash[String, untyped]
    end
  end
end
```

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
loader = Herb::Config::Loader.new
config = loader.load

# Explicit path
loader = Herb::Config::Loader.new(path: "/path/to/.herb.yml")
config = loader.load

# Validate configuration
validator = Herb::Config::Validator.new(config)
validator.validate!  # Raises ValidationError if invalid
```

**Access linter configuration:**

```ruby
linter = Herb::Config::LinterConfig.new(config)
linter.enabled?                    # => true
linter.include_patterns            # => ["**/*.html.erb", ...]
linter.rule_enabled?("html-img-require-alt")   # => true
linter.rule_severity("html-img-require-alt")   # => :error
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

### Environment Variables

| Variable | Description |
|----------|-------------|
| `HERB_CONFIG` | Override config file location |
| `HERB_NO_CONFIG` | Ignore config file, use defaults only |

## Testing Strategy

### Test Coverage Areas

**Herb::Config::Loader**
- Configuration file search (explicit path, env var, upward traversal)
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
