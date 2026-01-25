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
      def load: () -> Hash[Symbol, untyped]

      # Locate configuration file path
      def find_config_path: () -> String?

      private

      def load_from_file: (String path) -> Hash[Symbol, untyped]
      def parse_yaml: (String content) -> Hash[Symbol, untyped]
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

Validates configuration structure and values against the schema.

**Key Responsibilities:**
- Validate configuration type constraints (boolean, integer, array, hash)
- Verify glob patterns are well-formed
- Check rule names against known rules list
- Validate severity levels
- Collect and format validation errors

**Public Interface:**

```rbs
module Herb
  module Config
    class Validator
      attr_reader errors: Array[String]

      @config: Hash[Symbol, untyped]
      @known_rules: Array[String]
      @errors: Array[String]

      def initialize: (Hash[Symbol, untyped] config, ?known_rules: Array[String]) -> void

      # Check if configuration is valid
      def valid?: () -> bool

      # Validate and raise exception if invalid
      # @raise [ValidationError] With formatted error messages
      def validate!: () -> void

      private

      def validate_linter_section: () -> void
      def validate_formatter_section: () -> void
      def validate_rules: (Hash[String | Symbol, untyped] rules) -> void
      def validate_severity: (String | Symbol severity, String rule_name) -> void
      def validate_glob_array: (Array[String] patterns, String field_name) -> void
      def add_error: (String message) -> void
    end
  end
end
```

**Validation Rules:**
- **Linter section**: `enabled` (boolean), `include/exclude` (glob arrays), `rules` (hash)
- **Formatter section**: `enabled` (boolean), `indentWidth/maxLineLength` (positive integers), `include/exclude` (glob arrays), `rewriter` (hash with pre/post arrays)
- **Rule configuration**: Rule names must be in known_rules list, severity must be valid
- **Severity levels**: error, warn, warning, info, hint, off

### Herb::Config::Schema

Defines the structure and constraints of valid configuration.

**Key Responsibilities:**
- Define configuration field types and defaults
- Specify valid severity levels
- Provide severity normalization (handle aliases)

**Data Structures:**

```rbs
module Herb
  module Config
    module Schema
      type schemaField = { type: Symbol, default: untyped }
      type schemaDefinition = Hash[Symbol, schemaField]

      # Linter configuration schema
      LINTER: schemaDefinition

      # Formatter configuration schema
      FORMATTER: schemaDefinition

      SEVERITY_LEVELS: Array[Symbol]
      SEVERITY_ALIASES: Hash[String, Symbol]

      def self.normalize_severity: (String | Symbol severity) -> Symbol
      def self.valid_severity?: (String | Symbol severity) -> bool
    end
  end
end
```

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

      def self.config: () -> Hash[Symbol, untyped]

      def self.merge: (Hash[Symbol, untyped] user_config) -> Hash[Symbol, untyped]

      private

      def self.deep_merge: (Hash[Symbol, untyped] base, Hash[Symbol, untyped] override) -> Hash[Symbol, untyped]
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
      @config: Hash[Symbol, untyped]
      @linter_config: Hash[Symbol, untyped]

      def initialize: (Hash[Symbol, untyped] config) -> void

      def enabled?: () -> bool

      def include_patterns: () -> Array[String]

      def exclude_patterns: () -> Array[String]

      def rules: () -> Hash[String, untyped]

      def rule_enabled?: (String rule_name) -> bool

      def rule_severity: (String rule_name, ?default: Symbol) -> Symbol

      def rule_options: (String rule_name) -> Hash[Symbol, untyped]

      private

      def normalize_rule_name: (String | Symbol rule_name) -> String
      def extract_severity: (String | Symbol | Hash[Symbol, untyped] rule_config) -> Symbol
      def extract_options: (String | Symbol | Hash[Symbol, untyped] rule_config) -> Hash[Symbol, untyped]
    end
  end
end
```

**Rule Configuration Formats:**
- String/Symbol: `"alt-text": "error"` (severity only)
- Hash: `"alt-text": { severity: "error", options: { ... } }` (severity + options)
- Default: Rules not specified are enabled with `:warning` severity

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
      @config: Hash[Symbol, untyped]
      @formatter_config: Hash[Symbol, untyped]

      def initialize: (Hash[Symbol, untyped] config) -> void

      def enabled?: () -> bool

      def indent_width: () -> Integer

      def max_line_length: () -> Integer

      def include_patterns: () -> Array[String]

      def exclude_patterns: () -> Array[String]

      def pre_rewriters: () -> Array[String]

      def post_rewriters: () -> Array[String]

      private

      def rewriter_config: () -> Hash[Symbol, untyped]
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
validator = Herb::Config::Validator.new(config, known_rules: ["alt-text", "attribute-quotes"])
validator.validate!  # Raises ValidationError if invalid
```

**Access linter configuration:**

```ruby
linter = Herb::Config::LinterConfig.new(config)
linter.enabled?                    # => true
linter.include_patterns            # => ["**/*.html.erb", ...]
linter.rule_enabled?("alt-text")   # => true
linter.rule_severity("alt-text")   # => :error
linter.rule_options("alt-text")    # => { ... }
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

## Related Documentation

- [Overall Architecture](./architecture.md)
- [Requirements: Configuration](../requirements/config.md)
