# Phase 2: herb-core gem (Minimal Implementation)

## Overview

Implementation of the gem that provides common utilities. Provides file discovery functionality.

**Dependencies:** Phase 1 (herb-config) must be completed

**Task count:** 3

---

## Task 2.1: Create Gem Skeleton ✅

### Implementation

- [x] Run `bundle gem herb-core --test=rspec --linter=rubocop`
- [x] Edit `herb-core.gemspec` file
  - [x] Remove TODO comments
  - [x] Fill in `summary`, `description`, `homepage`
  - [x] Set `required_ruby_version` to `">= 3.3.0"`
  - [x] Add dependency on `herb` gem (commented out until herb gem is available)
- [x] Delete unnecessary files
  - [x] Delete `bin/console`
  - [x] Delete `bin/setup`

### Verification

```bash
cd herb-core
bundle install
bundle exec rspec
```

**Expected result:** `0 examples, 0 failures`

---

## Task 2.2: Add herb-core to CI ✅

### Overview

Add herb-core gem to the existing CI workflow.

### Implementation

- [x] Update `.github/workflows/ci.yml`
  - [x] Add herb-core job (same structure as herb-config job)
- [x] Create `herb-core/Steepfile`
  - [x] Configure target directories
  - [x] Configure library dependencies
- [x] Create `herb-core/rbs_collection.yaml`
  - [x] Configure RBS collection dependencies

### Updated Workflow Structure

```yaml
# Add this job to .github/workflows/ci.yml
herb-core:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: herb-core
  steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.3'
        bundler-cache: true
        working-directory: herb-core
    - name: Run tests
      run: bundle exec rspec
    - name: Install RBS dependencies
      run: bundle exec rbs collection install --frozen
    - name: Run type check
      run: bundle exec steep check
```

### Verification

```bash
# Verify Steepfile exists
ls herb-core/Steepfile

# Verify CI includes herb-core job
grep -A5 "herb-core:" .github/workflows/ci.yml
```

**Expected result:** CI passes for herb-core on GitHub

---

## Task 2.3: Implement FileDiscovery (Simplified Version) ✅

### Implementation

- [x] Create `lib/herb/core/file_discovery.rb`
  - [x] Implement `initialize(base_dir:, include_patterns:, exclude_patterns:)`
  - [x] Implement `discover(paths = [])` instance method
  - [x] Implement file discovery using `Dir.glob`
  - [x] Discovery from patterns (`include_patterns` attribute)
  - [x] Discovery from path specification (`paths` parameter)
  - [x] Apply exclusion patterns (`exclude_patterns` attribute)
  - [x] Remove duplicate files
- [x] Require in `lib/herb/core.rb`
- [x] Create `spec/herb/core/file_discovery_spec.rb`
  - [x] Test file discovery from patterns
  - [x] Test file discovery from path specification
  - [x] Test exclusion patterns
  - [x] Test duplicate removal

### Implementation Specification

```ruby
# Usage example
discovery = Herb::Core::FileDiscovery.new(
  base_dir: Dir.pwd,
  include_patterns: ["**/*.html.erb"],
  exclude_patterns: ["vendor/**/*"]
)

# When no paths provided: discover from include patterns
files = discovery.discover
# => ["app/views/users/index.html.erb", "app/views/posts/index.html.erb", ...]

# When paths provided: discover only from specified paths (files or directories)
files = discovery.discover(["app/views/users/show.html.erb"])
# => ["app/views/users/show.html.erb"]

files = discovery.discover(["app/views/users"])
# => ["app/views/users/index.html.erb", "app/views/users/show.html.erb", ...]
```

**Behavior:**
- `paths` is empty: Use `include_patterns` to discover files, applying `exclude_patterns`
- `paths` contains files: Return files directly **without** applying `exclude_patterns` (explicit file = user intent is clear)
- `paths` contains directories: Discover files in directory **with** `exclude_patterns` applied (directory = automatic discovery within)

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

- [x] All tasks (2.1–2.3) completed
- [x] CI passes for herb-core
- [x] `bundle exec rspec` passes all tests
- [x] `herb-core` gem builds successfully (`gem build herb-core.gemspec` succeeds)

---

## Next Phase

After Phase 2 is complete, proceed to [Phase 3: herb-lint gem Foundation](./phase-3-herb-lint-foundation.md).
