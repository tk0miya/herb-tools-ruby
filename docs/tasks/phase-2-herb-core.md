# Phase 2: herb-core gem (Minimal Implementation)

## Overview

Implementation of the gem that provides common utilities. Provides file discovery functionality.

**Dependencies:** Phase 1 (herb-config) must be completed

**Task count:** 3

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

## Task 2.2: Add herb-core to CI

### Overview

Add herb-core gem to the existing CI workflow.

### Implementation

- [ ] Update `.github/workflows/ci.yml`
  - [ ] Add herb-core job (same structure as herb-config job)
- [ ] Create `herb-core/Steepfile`
  - [ ] Configure target directories
  - [ ] Configure library dependencies
- [ ] Create `herb-core/rbs_collection.yaml`
  - [ ] Configure RBS collection dependencies

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

## Task 2.3: Implement FileDiscovery (Simplified Version)

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

- [ ] All tasks (2.1–2.3) completed
- [ ] CI passes for herb-core
- [ ] `bundle exec rspec` passes all tests
- [ ] `herb-core` gem builds successfully (`gem build herb-core.gemspec` succeeds)

---

## Next Phase

After Phase 2 is complete, proceed to [Phase 3: herb-lint gem Foundation](./phase-3-herb-lint-foundation.md).
