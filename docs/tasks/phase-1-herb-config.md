# Phase 1: herb-config gem (Minimal Implementation)

## Overview

Implementation of the gem responsible for configuration management. Loads `.herb.yml` files, merges with default settings, and provides linter configuration.

**Dependencies:** None (first phase)

**Task count:** 5

---

## Task 1.1: Create Gem Skeleton

### Implementation

- [x] Run `bundle gem herb-config --test=rspec --linter=rubocop`
- [x] Edit `herb-config.gemspec` file
  - [x] Remove TODO comments
  - [x] Fill in `summary`, `description`, `homepage`
  - [x] Set `required_ruby_version` to `">= 3.3.0"`
  - [x] Add dependency on `herb` gem (`spec.add_dependency "herb", "~> 0.1"`)
- [x] Delete unnecessary files
  - [x] Delete `bin/console`
  - [x] Delete `bin/setup`

### Verification

```bash
cd herb-config
bundle install
bundle exec rspec
```

**Expected result:** `0 examples, 0 failures`

---

## Task 1.2: Setup CI for herb-config

### Overview

Setup GitHub Actions CI to run tests and type checking for herb-config gem.

### Implementation

- [ ] Create `.github/workflows/ci.yml`
  - [ ] Configure Ruby 3.3 setup
  - [ ] Configure job for herb-config gem
  - [ ] Run `bundle install`
  - [ ] Run `bundle exec rspec`
  - [ ] Run `bundle exec rbs collection install --frozen` to install RBS dependencies
  - [ ] Run `bundle exec steep check` for type checking
- [ ] Create `herb-config/Steepfile`
  - [ ] Configure target directories
  - [ ] Configure library dependencies
- [ ] Create `herb-config/rbs_collection.yaml`
  - [ ] Configure RBS collection dependencies

### Workflow Structure

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  herb-config:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: herb-config
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true
          working-directory: herb-config
      - name: Run tests
        run: bundle exec rspec
      - name: Install RBS dependencies
        run: bundle exec rbs collection install --frozen
      - name: Run type check
        run: bundle exec steep check
```

### Verification

```bash
# Verify workflow syntax
cat .github/workflows/ci.yml

# Verify Steepfile exists
ls herb-config/Steepfile
```

**Expected result:** CI workflow file and Steepfile are created, CI passes on GitHub

---

## Task 1.3: Implement Defaults Module

### Implementation

- [ ] Create `lib/herb/config/defaults.rb`
  - [ ] Define `DEFAULT_INCLUDE` constant (`["**/*.html.erb"]`)
  - [ ] Define `DEFAULT_EXCLUDE` constant (`[]`)
  - [ ] Implement `Defaults.config` method (returns default settings Hash)
  - [ ] Implement `Defaults.merge` method (deep merge logic)
- [ ] Require in `lib/herb/config.rb`
- [ ] Create `spec/herb/config/defaults_spec.rb`
  - [ ] Test for `Defaults.config`
  - [ ] Test for `Defaults.merge` (including deep merge tests)

### Default Configuration Structure

```ruby
{
  "linter" => {
    "include" => ["**/*.html.erb"],
    "exclude" => [],
    "rules" => {}
  }
}
```

### Verification

```bash
bundle exec rspec spec/herb/config/defaults_spec.rb
```

**Expected result:** All tests pass

---

## Task 1.4: Implement Loader (Minimal Version)

### Implementation

- [ ] Create `lib/herb/config/loader.rb`
  - [ ] Search for `.herb.yml` in current directory
  - [ ] Load YAML file (use `YAML.safe_load`)
  - [ ] Merge with `Defaults`
  - [ ] Error handling (file not found → return Defaults, invalid YAML → raise exception)
- [ ] Require in `lib/herb/config.rb`
- [ ] Create `spec/herb/config/loader_spec.rb`
  - [ ] Test when `.herb.yml` exists
  - [ ] Test when `.herb.yml` is absent (returns Defaults)
  - [ ] Test with invalid YAML (raises exception)

### Search Path

1. `.herb.yml` in current directory
2. Use default configuration if not found

### Verification

```bash
bundle exec rspec spec/herb/config/loader_spec.rb
```

**Expected result:** All tests pass

---

## Task 1.5: Implement LinterConfig

### Implementation

- [ ] Create `lib/herb/config/linter_config.rb`
  - [ ] Implement `initialize(config_hash)`
  - [ ] Implement `include_patterns` method (returns `config["linter"]["include"]`)
  - [ ] Implement `exclude_patterns` method (returns `config["linter"]["exclude"]`)
  - [ ] Implement `rules` method (returns `config["linter"]["rules"]`)
  - [ ] Implement `rule_severity(rule_name)` method (returns rule severity)
- [ ] Require in `lib/herb/config.rb`
- [ ] Create `spec/herb/config/linter_config_spec.rb`
  - [ ] Test each method
  - [ ] Test rule configuration retrieval

### Verification

```bash
bundle exec rspec spec/herb/config/linter_config_spec.rb
```

**Expected result:** All tests pass

---

## Phase 1 Completion Criteria

- [ ] All tasks (1.1–1.5) completed
- [ ] CI passes for herb-config
- [ ] `bundle exec rspec` passes all tests
- [ ] `herb-config` gem builds successfully (`gem build herb-config.gemspec` succeeds)

---

## Next Phase

After Phase 1 is complete, proceed to [Phase 2: herb-core gem](./phase-2-herb-core.md).
