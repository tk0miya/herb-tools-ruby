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

## Component Details

### Herb::Core::FileDiscovery

**Interface:** See [`sig/herb/core/file_discovery.rbs`](../../herb-core/sig/herb/core/file_discovery.rbs)

Responsible for discovering files to process based on glob patterns and paths. Handles both pattern-based discovery (using include patterns) and path-based discovery (from CLI arguments).

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

**Interface:** See [`sig/herb/core/pattern_matcher.rbs`](../../herb-core/sig/herb/core/pattern_matcher.rbs)

Responsible for determining if a file path matches include/exclude/only patterns using glob pattern matching.

**Responsibilities:**
- Convert absolute paths to relative paths (from base directory)
- Match paths against glob patterns using File.fnmatch?
- Apply include/exclude logic (included AND NOT excluded)
- Support advanced glob patterns (**, {}, [], etc.)

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
  includes: ["**/*.html.erb"],
  excludes: ["vendor/**"],
  only: []
)

matcher.match?("app/views/index.html.erb")  # => true
matcher.match?("vendor/gems/template.html.erb")  # => false
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

## Related Documentation

- [Overall Architecture](./architecture.md)
- [herb-lint Design](./herb-lint-design.md)
- [herb-format Design](./herb-format-design.md)
- [Requirements: herb-lint](../requirements/herb-lint.md)
- [Requirements: herb-format](../requirements/herb-format.md)
