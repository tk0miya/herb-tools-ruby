# Phase 3: herb-lint gem Foundation

## Overview

Implementation of foundational data structures and rule infrastructure for the linter gem. Implements Offense, LintResult, AggregatedResult, and base classes for rules.

**Dependencies:** Phase 1 (herb-config) and Phase 2 (herb-core) must be completed

**Task count:** 4

---

## Task 3.1: Create Gem Skeleton

### Implementation

- [x] Run `bundle gem herb-lint --test=rspec --linter=rubocop`
- [x] Edit `herb-lint.gemspec` file
  - [x] Remove TODO comments
  - [x] Fill in `summary`, `description`, `homepage`
  - [x] Set `required_ruby_version` to `">= 3.3.0"`
  - [x] Add dependencies
    - [ ] `spec.add_dependency "herb", "~> 0.1"`
    - [x] `spec.add_dependency "herb-config", "~> 0.1.0"` (or local path)
    - [x] `spec.add_dependency "herb-core", "~> 0.1.0"` (or local path)
- [x] Create `exe/herb-lint` executable file
  - [x] Add shebang line (`#!/usr/bin/env ruby`)
  - [x] `require "herb/lint"`
  - [x] Call `Herb::Lint::CLI.new(ARGV).run`
  - [x] Grant execute permission with `chmod +x exe/herb-lint`

### Example Local Dependency Setup in Gemfile

```ruby
# herb-lint/Gemfile
gem "herb-config", path: "../herb-config"
gem "herb-core", path: "../herb-core"
```

### Verification

```bash
cd herb-lint
bundle install
bundle exec rspec
```

**Expected result:** `0 examples, 0 failures`

---

## Task 3.2: Add herb-lint to CI

### Overview

Add herb-lint gem to the existing CI workflow.

### Implementation

- [x] Update `.github/workflows/ci.yml`
  - [x] Add herb-lint job (same structure as herb-config/herb-core jobs)
- [x] Create `herb-lint/Steepfile`
  - [x] Configure target directories
  - [x] Configure library dependencies (including herb-config, herb-core)
- [x] Create `herb-lint/rbs_collection.yaml`
  - [x] Configure RBS collection dependencies

### Updated Workflow Structure

```yaml
# Add this job to .github/workflows/ci.yml
herb-lint:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: herb-lint
  steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.3'
        bundler-cache: true
        working-directory: herb-lint
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
ls herb-lint/Steepfile

# Verify CI includes herb-lint job
grep -A5 "herb-lint:" .github/workflows/ci.yml
```

**Expected result:** CI passes for herb-lint on GitHub

---

## Task 3.3: Implement Data Structures

### Implementation

#### Offense Class

- [ ] Create `lib/herb/lint/offense.rb`
  - [ ] Implement `initialize(rule_name:, message:, severity:, location:)`
  - [ ] `attr_reader :rule_name, :message, :severity, :location`
  - [ ] Implement `line` method (returns `location.start_line`)
  - [ ] Implement `column` method (returns `location.start_column`)
- [ ] Create `spec/herb/lint/offense_spec.rb`

#### LintResult Class

- [ ] Create `lib/herb/lint/lint_result.rb`
  - [ ] Implement `initialize(file_path:, offenses:, source:)`
  - [ ] `attr_reader :file_path, :offenses, :source`
  - [ ] Implement `error_count` method (count severity == "error")
  - [ ] Implement `warning_count` method (count severity == "warning")
  - [ ] Implement `offense_count` method (offenses.size)
- [ ] Create `spec/herb/lint/lint_result_spec.rb`

#### AggregatedResult Class

- [ ] Create `lib/herb/lint/aggregated_result.rb`
  - [ ] Implement `initialize(results)`
  - [ ] `attr_reader :results`
  - [ ] Implement `offense_count` method (total across all results)
  - [ ] Implement `error_count` method (total across all results)
  - [ ] Implement `warning_count` method (total across all results)
  - [ ] Implement `file_count` method (results.size)
  - [ ] Implement `success?` method (offense_count == 0)
- [ ] Create `spec/herb/lint/aggregated_result_spec.rb`

#### Entry Point

- [ ] Require each class in `lib/herb/lint.rb`

### Verification

```bash
bundle exec rspec spec/herb/lint/offense_spec.rb
bundle exec rspec spec/herb/lint/lint_result_spec.rb
bundle exec rspec spec/herb/lint/aggregated_result_spec.rb
```

**Expected result:** All tests pass

---

## Task 3.4: Implement Rule Infrastructure

### Implementation

#### Base Class

- [ ] Create `lib/herb/lint/rules/base.rb`
  - [ ] Define class method `rule_name`
  - [ ] Define class method `description`
  - [ ] Define class method `default_severity`
  - [ ] Implement `initialize` (accept optional `severity:` and `options:`)
  - [ ] Define `check(document, context)` method interface (abstract method)
  - [ ] Implement `create_offense(context:, message:, location:)` helper method
- [ ] Create `spec/herb/lint/rules/base_spec.rb`

#### VisitorRule Class

- [ ] Create `lib/herb/lint/rules/visitor_rule.rb`
  - [ ] Inherit from `Base`
  - [ ] Include `Herb::Visitor`
  - [ ] Implement `initialize` (call `super`)
  - [ ] Implement `check(document, context)` method
    - [ ] Initialize `@offenses = []`, `@context = context`
    - [ ] Call `document.visit(self)` to traverse AST
    - [ ] Return `@offenses`
  - [ ] Implement `add_offense(message:, location:)` helper method
    - [ ] Call `create_offense` and add to `@offenses`
- [ ] Create `spec/herb/lint/rules/visitor_rule_spec.rb`

#### Entry Point

- [ ] Require each class in `lib/herb/lint.rb`

### Rule Implementation Example

```ruby
# Example rule that inherits from VisitorRule
class MyRule < Herb::Lint::Rules::VisitorRule
  def self.rule_name = "my-rule"
  def self.description = "My custom rule"
  def self.default_severity = "error"

  def visit_html_element_node(node)
    add_offense(
      message: "Found an element",
      location: node.location
    )
    super
  end
end

# Rule usage example
rule = MyRule.new
document = Herb.parse(source)
context = Herb::Lint::Context.new(
  file_path: "example.html.erb",
  source: source,
  config: config
)
offenses = rule.check(document, context)
```

### Verification

```bash
bundle exec rspec spec/herb/lint/rules/base_spec.rb
bundle exec rspec spec/herb/lint/rules/visitor_rule_spec.rb
```

**Expected result:** All tests pass

---

## Phase 3 Completion Criteria

- [ ] All tasks (3.1–3.4) completed
- [ ] CI passes for herb-lint
- [ ] `bundle exec rspec` passes all tests
- [ ] Data structure classes work correctly
- [ ] Rule infrastructure classes work correctly

---

## Next Phase

After Phase 3 is complete, proceed to [Phase 4: Rule Implementation](./phase-4-rules.md).
