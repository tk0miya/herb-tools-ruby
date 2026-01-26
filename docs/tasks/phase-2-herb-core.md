# Phase 2: herb-core gem (Minimal Implementation)

## Overview

Implementation of the gem that provides common utilities. Provides file discovery functionality.

**Dependencies:** Phase 1 (herb-config) must be completed

**Task count:** 2

---

## Task 2.1: Create Gem Skeleton

### Implementation

- [ ] Run `bundle gem herb-core --test=rspec --linter=rubocop`
- [ ] Edit `herb-core.gemspec` file
  - [ ] Remove TODO comments
  - [ ] Fill in `summary`, `description`, `homepage`
  - [ ] Set `required_ruby_version` to `">= 3.3.0"`
  - [ ] Add dependency on `herb` gem (`spec.add_dependency "herb", "~> 0.1"`)
- [ ] Delete unnecessary files
  - [ ] Delete `bin/console`
  - [ ] Delete `bin/setup`

### Verification

```bash
cd herb-core
bundle install
bundle exec rspec
```

**Expected result:** `0 examples, 0 failures`

---

## Task 2.2: Implement FileDiscovery (Simplified Version)

### Implementation

- [ ] Create `lib/herb/core/file_discovery.rb`
  - [ ] Implement `initialize(base_dir:, include_patterns:, exclude_patterns:)`
  - [ ] Implement `discover(paths = [])` instance method
  - [ ] Implement file discovery using `Dir.glob`
  - [ ] Discovery from patterns (`include_patterns` attribute)
  - [ ] Discovery from path specification (`paths` parameter)
  - [ ] Apply exclusion patterns (`exclude_patterns` attribute)
  - [ ] Remove duplicate files
- [ ] Require in `lib/herb/core.rb`
- [ ] Create `spec/herb/core/file_discovery_spec.rb`
  - [ ] Test file discovery from patterns
  - [ ] Test file discovery from path specification
  - [ ] Test exclusion patterns
  - [ ] Test duplicate removal

### Implementation Specification

```ruby
# Usage example
discovery = Herb::Core::FileDiscovery.new(
  base_dir: Dir.pwd,
  include_patterns: ["**/*.html.erb"],
  exclude_patterns: ["vendor/**/*"]
)

files = discovery.discover(["app/views/users/show.html.erb"])
# => ["app/views/users/show.html.erb", "app/views/posts/index.html.erb", ...]
```

### Simplified Implementation for MVP Scope

- Use simple `Dir.glob`
- Do not support complex glob exclusion rules
- No need to consider `.gitignore`

### Verification

```bash
bundle exec rspec spec/herb/core/file_discovery_spec.rb
```

**Expected result:** All tests pass

---

## Phase 2 Completion Criteria

- [ ] All tasks (2.1–2.2) completed
- [ ] `bundle exec rspec` passes all tests
- [ ] `herb-core` gem builds successfully (`gem build herb-core.gemspec` succeeds)

---

## Next Phase

After Phase 2 is complete, proceed to [Phase 3: herb-lint gem Foundation](./phase-3-herb-lint-foundation.md).
