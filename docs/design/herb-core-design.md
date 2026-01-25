# herb-core Detailed Design

Detailed design document for the common component gem.

## Overview

herb-core is a gem that provides common functionality shared by herb-lint and herb-format. It handles file discovery, pattern matching, and parsing of inline disable comments.

## Directory Structure

```
herb-core/
├── lib/
│   └── herb/
│       └── core/
│           ├── version.rb
│           ├── file_discovery.rb
│           ├── pattern_matcher.rb
│           └── directive_parser.rb
├── spec/
│   └── herb/
│       └── core/
│           ├── file_discovery_spec.rb
│           ├── pattern_matcher_spec.rb
│           └── directive_parser_spec.rb
├── herb-core.gemspec
└── Gemfile
```

## Class Design

### Module Structure

```
Herb::Core
├── FileDiscovery    # File discovery, glob processing
├── PatternMatcher   # include/exclude pattern matching
└── DirectiveParser  # Parsing inline disable comments
    ├── Directive    # Parsed directive
    └── DirectiveType # Types of directives
```

## Component Details

### Herb::Core::FileDiscovery

Responsible for discovering files to process based on glob patterns and paths. Handles both pattern-based discovery (using include patterns) and path-based discovery (from CLI arguments).

```rbs
class Herb::Core::FileDiscovery
  @base_dir: String
  @include_patterns: Array[String]
  @exclude_patterns: Array[String]
  @pattern_matcher: Herb::Core::PatternMatcher

  attr_reader base_dir: String
  attr_reader include_patterns: Array[String]
  attr_reader exclude_patterns: Array[String]

  def initialize: (base_dir: String, include_patterns: Array[String], exclude_patterns: Array[String]) -> void

  # Discover files based on provided paths or include patterns
  # Paths specified via CLI (uses include patterns if empty)
  # Returns list of matched file paths
  def discover: (?Array[String] paths) -> Array[String]
end
```

**Responsibilities:**
- Expand glob patterns from include list
- Process both file and directory paths from CLI
- Delegate include/exclude filtering to PatternMatcher
- Return sorted, unique list of file paths

### Herb::Core::PatternMatcher

Responsible for determining if a file path matches include/exclude patterns using glob pattern matching.

```rbs
class Herb::Core::PatternMatcher
  @include_patterns: Array[String]
  @exclude_patterns: Array[String]
  @base_dir: String

  attr_reader include_patterns: Array[String]
  attr_reader exclude_patterns: Array[String]
  attr_reader base_dir: String

  def initialize: (include_patterns: Array[String], exclude_patterns: Array[String], base_dir: String) -> void

  # Check if path matches patterns (included and not excluded)
  def match?: (String path) -> bool

  # Check if path matches any include pattern
  def included?: (String relative_path) -> bool

  # Check if path matches any exclude pattern
  def excluded?: (String relative_path) -> bool
end
```

**Responsibilities:**
- Convert absolute paths to relative paths (from base directory)
- Match paths against glob patterns using File.fnmatch?
- Apply include/exclude logic (included AND NOT excluded)
- Support advanced glob patterns (**, {}, [], etc.)

### Herb::Core::DirectiveParser

Responsible for parsing inline disable/enable comments (e.g., `<%# herb:disable alt-text %>`) from ERB templates. Supports both linter and formatter directives.

#### Data Structures

```rbs
module Herb::Core::DirectiveParser::DirectiveType
  DISABLE: Symbol
  ENABLE: Symbol
  DISABLE_ALL: Symbol
  ENABLE_ALL: Symbol
  IGNORE_FILE: Symbol
  FORMATTER_OFF: Symbol
  FORMATTER_ON: Symbol
  FORMATTER_IGNORE: Symbol
end

class Herb::Core::DirectiveParser::Directive
  @type: Symbol
  @rules: Array[String]
  @line: Integer
  @scope: Symbol

  attr_reader type: Symbol
  attr_reader rules: Array[String]
  attr_reader line: Integer
  attr_reader scope: Symbol

  def initialize: (type: Symbol, rules: Array[String], line: Integer, scope: Symbol) -> void
end
```

#### Public Interface

```rbs
class Herb::Core::DirectiveParser
  @source: String
  @mode: Symbol
  @directives: Array[Directive]

  attr_reader source: String
  attr_reader mode: Symbol

  def initialize: (String source, ?mode: Symbol) -> void

  # Parse all directives from source
  def parse: () -> Array[Directive]

  # Check if entire file should be ignored
  def ignore_file?: () -> bool

  # Check if rule is disabled at specific line
  # rule_name: Rule name (nil for all rules)
  def disabled_at?: (Integer line, ?String? rule_name) -> bool
end
```

**Responsibilities:**
- Parse ERB comments containing herb directives
- Support linter directives (disable, enable, linter ignore)
- Support formatter directives (formatter off, formatter on, formatter ignore)
- Track directive scopes (:next_line, :range, :file)
- Compute rule enable/disable state at any line
- Handle multiple rules in a single directive (comma-separated)

### Herb::Core::DisableTracker

Helper class for tracking rule enable/disable state across a file. Provides a higher-level interface for querying whether rules are enabled at specific lines.

```rbs
class Herb::Core::DisableTracker
  @directives: Array[Herb::Core::DirectiveParser::Directive]

  attr_reader directives: Array[Herb::Core::DirectiveParser::Directive]

  def initialize: (Array[Herb::Core::DirectiveParser::Directive] directives) -> void

  # Check if entire file should be ignored
  def ignore_file?: () -> bool

  # Check if rule is enabled at specific line
  def rule_enabled_at?: (Integer line, String rule_name) -> bool

  # Filter enabled rules at specific line
  # Returns list of enabled rule names
  def filter_enabled_rules: (Integer line, Array[String] rule_names) -> Array[String]
end
```

**Responsibilities:**
- Track cumulative enable/disable state across directives
- Compute rule state at any line by processing all prior directives
- Handle file-level ignore directives
- Apply directive scopes correctly (file, next_line, range)
- Support both "all rules" and "specific rules" disable/enable

## Public API

### Using FileDiscovery

```ruby
require "herb/core"

discovery = Herb::Core::FileDiscovery.new(
  base_dir: "/path/to/project",
  include_patterns: ["**/*.html.erb", "**/*.turbo_stream.erb"],
  exclude_patterns: ["vendor/**", "node_modules/**"]
)

# Discover from include patterns (when no paths provided)
files = discovery.discover
# => ["/path/to/project/app/views/users/index.html.erb", ...]

# Discover from specific paths
files = discovery.discover(["app/views/users"])
# => ["/path/to/project/app/views/users/index.html.erb", ...]
```

### Using PatternMatcher

```ruby
require "herb/core"

matcher = Herb::Core::PatternMatcher.new(
  include_patterns: ["**/*.html.erb"],
  exclude_patterns: ["vendor/**"],
  base_dir: "/path/to/project"
)

matcher.match?("/path/to/project/app/views/index.html.erb")  # => true
matcher.match?("/path/to/project/vendor/gems/template.html.erb")  # => false
```

### Using DirectiveParser

```ruby
require "herb/core"

source = <<~ERB
  <%# herb:disable alt-text %>
  <img src="decorative.png">
  <%# herb:disable all %>
  <div onclick="handler()">Click</div>
ERB

parser = Herb::Core::DirectiveParser.new(source, mode: :linter)

# Parse all directives
directives = parser.parse
# => [Directive(...), Directive(...)]

# Check if file should be ignored
parser.ignore_file?  # => false

# Check if rule is disabled at specific line
parser.disabled_at?(2, "alt-text")  # => true
parser.disabled_at?(4, "valid-tag-nesting")  # => true (all disabled)
```

### Using DisableTracker

```ruby
require "herb/core"

parser = Herb::Core::DirectiveParser.new(source, mode: :linter)
tracker = Herb::Core::DisableTracker.new(parser.parse)

# Check if file should be ignored
tracker.ignore_file?  # => false

# Check if rule is enabled at line
tracker.rule_enabled_at?(2, "alt-text")  # => false
tracker.rule_enabled_at?(2, "attribute-quotes")  # => true

# Filter rules that are enabled
enabled = tracker.filter_enabled_rules(2, ["alt-text", "attribute-quotes"])
# => ["attribute-quotes"]
```

## Glob Pattern Support

The following glob patterns are supported:

| Pattern | Description | Example |
|---------|-------------|---------|
| `*` | Any characters (except `/`) | `*.erb` |
| `**` | Any characters (including `/`) | `**/*.erb` |
| `?` | Any single character | `file?.erb` |
| `[abc]` | Any character in brackets | `[abc].erb` |
| `[a-z]` | Character range | `[a-z].erb` |
| `{a,b}` | Either pattern | `*.{erb,haml}` |

## Testing Strategy

### Unit Tests

Tests should verify the public interface of each component:

**FileDiscovery Tests:**
- Pattern-based discovery (using include patterns)
- Path-based discovery (files and directories)
- Include/exclude pattern application
- Handling of non-existent paths

**PatternMatcher Tests:**
- Glob pattern matching (*, **, ?, [], {})
- Include pattern matching
- Exclude pattern matching
- Combined include/exclude logic
- Relative path conversion

**DirectiveParser Tests:**
- Parsing linter directives (disable, enable, disable all, enable all)
- Parsing formatter directives (off, on, ignore)
- Multiple rules in single directive
- File-level ignore detection
- Line-level disable state computation
- Directive scope handling (next_line, range, file)

**DisableTracker Tests:**
- File-level ignore state
- Rule enable/disable tracking across lines
- Filtering enabled rules
- Handling "disable all" / "enable all"
- Range-based enable/disable

## Related Documentation

- [Overall Architecture](./architecture.md)
- [herb-lint Design](./herb-lint-design.md)
- [Requirements: herb-lint](../requirements/herb-lint.md)
