# herb-core Detailed Design

Detailed design document for the common component gem.

## Overview

herb-core is a gem that provides common functionality shared by herb-lint and herb-format. It handles file discovery and pattern matching.

## Directory Structure

```
herb-core/
├── lib/
│   └── herb/
│       └── core/
│           ├── version.rb
│           ├── file_discovery.rb
│           └── pattern_matcher.rb
├── spec/
│   └── herb/
│       └── core/
│           ├── file_discovery_spec.rb
│           └── pattern_matcher_spec.rb
├── herb-core.gemspec
└── Gemfile
```

## Class Design

### Module Structure

```
Herb::Core
├── FileDiscovery    # File discovery, glob processing
└── PatternMatcher   # include/exclude pattern matching
```

> **Note:** Inline directive parsing (formerly planned as `DirectiveParser`) is implemented in each tool gem rather than herb-core. See [herb-lint Design](./herb-lint-design.md) for the linter's directive components.

## Component Details

### Herb::Core::FileDiscovery

Responsible for discovering files to process based on glob patterns and paths. Handles both pattern-based discovery (using include patterns) and path-based discovery (from CLI arguments).

```rbs
class Herb::Core::FileDiscovery
  @base_dir: String
  @include_patterns: Array[String]
  @exclude_patterns: Array[String]

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
- Apply exclude pattern filtering based on path type
- Return sorted, unique list of file paths

**Exclude Pattern Application Rules:**

| Input Type | Exclude Applied | Rationale |
|------------|-----------------|-----------|
| No paths (pattern-based) | Yes | Automatic discovery, filtering expected |
| Explicit file path | No | User intent is clear, they want this specific file |
| Directory path | Yes | Directory triggers automatic discovery within |

### Herb::Core::PatternMatcher

> **MVP Note:** In the MVP implementation, PatternMatcher functionality is integrated within FileDiscovery (`excluded?` method). This class may be separated in a future enhancement for improved reusability.

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

### Inline Directive Handling

> **Design Decision:** Inline directive parsing is implemented in each tool gem (herb-lint, herb-format) rather than in herb-core. This follows the TypeScript reference implementation where `herb-disable-comment-utils.ts` and `linter-ignore.ts` reside in the linter package. Each tool has its own directive format (e.g., `herb:disable` for the linter, `herb:formatter off` for the formatter), so tool-specific implementations are more appropriate than a shared abstraction.
>
> See [herb-lint Design](./herb-lint-design.md) for the linter directive components: `DisableComment`, `DisableCommentParser`, and `LinterIgnore`.

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

### Inline Directives

Inline directive parsing is handled by each tool gem. See [herb-lint Design](./herb-lint-design.md) for linter directive usage examples.

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

Inline directive tests are located in each tool gem. See [herb-lint Design](./herb-lint-design.md) for linter directive test strategy.

## Related Documentation

- [Overall Architecture](./architecture.md)
- [herb-lint Design](./herb-lint-design.md)
- [Requirements: herb-lint](../requirements/herb-lint.md)
