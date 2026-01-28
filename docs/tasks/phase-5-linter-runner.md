# Phase 5: Linter & Runner Implementation

## Overview

Implementation of RuleRegistry, Context, Linter, and Runner. These components complete the flow from file discovery to lint execution.

**Dependencies:** Phase 4 (rule implementation) must be completed

**Task count:** 4

---

## Task 5.1: Implement RuleRegistry (Simplified Version)

### Implementation

- [x] Create `lib/herb/lint/rule_registry.rb`
  - [x] Manage registration with `@@rules = {}` class variable
  - [x] Implement `RuleRegistry.register(rule_class)` class method
  - [x] Implement `RuleRegistry.all` class method (returns all rules as array)
  - [x] Implement `RuleRegistry.get(rule_name)` class method (get rule by name)
  - [x] Implement `RuleRegistry.load_builtin_rules` class method
    - [x] Hard-code registration of rules implemented in Phase 4
    - [x] Register `A11y::AltText`
    - [x] Register `Html::AttributeQuotes`
- [x] Require in `lib/herb/lint.rb`
- [x] Create `spec/herb/lint/rule_registry_spec.rb`
  - [x] Test `register`
  - [x] Test `all`
  - [x] Test `get`
  - [x] Test `load_builtin_rules`

### Implementation Example

```ruby
module Herb
  module Lint
    class RuleRegistry
      @@rules = {}

      def self.register(rule_class)
        @@rules[rule_class.rule_name] = rule_class
      end

      def self.all
        @@rules.values
      end

      def self.get(rule_name)
        @@rules[rule_name]
      end

      def self.load_builtin_rules
        require_relative "rules/html/alt_text"
        require_relative "rules/html/attribute_quotes"

        register(Rules::Html::AltText)
        register(Rules::Html::AttributeQuotes)
      end
    end
  end
end
```

### Verification

```bash
bundle exec rspec spec/herb/lint/rule_registry_spec.rb
```

**Expected result:** All tests pass

---

## Task 5.2: Implement Context

### Implementation

- [x] Create `lib/herb/lint/context.rb`
  - [x] Implement `initialize(file_path:, source:, config:)`
  - [x] `attr_reader :file_path, :source, :config`
  - [x] Implement `severity_for(rule_name)` method
    - [x] Get rule severity from configuration
    - [x] Use rule's default severity if not in configuration
- [x] Require in `lib/herb/lint.rb`
- [x] Create `spec/herb/lint/context_spec.rb`
  - [x] Test attribute retrieval
  - [x] Test `severity_for` (with/without configuration)

### Implementation Hints

```ruby
def severity_for(rule_name)
  # Get from config.rules[rule_name]
  # Use corresponding Rule class's default_severity if not found
  config.rules.dig(rule_name, "severity") ||
    RuleRegistry.get(rule_name)&.default_severity ||
    "error"
end
```

### Verification

```bash
bundle exec rspec spec/herb/lint/context_spec.rb
```

**Expected result:** All tests pass

---

## Task 5.3: Implement Linter

### Implementation

- [x] Create `lib/herb/lint/linter.rb`
  - [x] Implement `initialize(rules, config)`
  - [x] `attr_reader :rules, :config`
  - [x] Implement `lint(file_path:, source:)` method
    - [x] Generate AST with `Herb.parse(source)`
    - [x] Generate `Context`
    - [x] Call each rule's `check(document, context)`
    - [x] Collect all offenses
    - [x] Generate and return `LintResult`
  - [x] Parse error handling
    - [x] Generate special offense on parse error
- [x] Require in `lib/herb/lint.rb`
- [x] Create `spec/herb/lint/linter_spec.rb`
  - [x] Normal case: test offense detection
  - [x] Normal case: test no offenses
  - [x] Error case: test parse error handling

### Implementation Hints

```ruby
def lint(file_path:, source:)
  document = Herb.parse(source)
  context = Context.new(
    file_path: file_path,
    source: source,
    config: config
  )

  offenses = []
  rules.each do |rule|
    offenses.concat(rule.check(document, context))
  end

  LintResult.new(
    file_path: file_path,
    offenses: offenses,
    source: source
  )
rescue Herb::ParseError => e
  # Treat parse error as special offense
  offense = Offense.new(
    rule_name: "parse-error",
    message: e.message,
    severity: "error",
    location: e.location
  )
  LintResult.new(
    file_path: file_path,
    offenses: [offense],
    source: source
  )
end
```

### Verification

```bash
bundle exec rspec spec/herb/lint/linter_spec.rb
```

**Expected result:** All tests pass

---

## Task 5.4: Implement Runner

### Implementation

- [ ] Create `lib/herb/lint/runner.rb`
  - [ ] Implement `initialize(config)`
  - [ ] `attr_reader :config`
  - [ ] Implement `run(paths)` method
    - [ ] Generate `FileDiscovery` instance and discover files
      - [ ] Use `paths` parameter
      - [ ] Use `config.include_patterns`
      - [ ] Use `config.exclude_patterns`
    - [ ] Get enabled rules (from `RuleRegistry`)
    - [ ] Generate rule instances
    - [ ] Generate `Linter` instance
    - [ ] Read each file
    - [ ] Process each file with `Linter#lint`
    - [ ] Collect all results
    - [ ] Generate and return `AggregatedResult`
- [ ] Require in `lib/herb/lint.rb`
- [ ] Create `spec/herb/lint/runner_spec.rb`
  - [ ] Test file discovery
  - [ ] Test processing multiple files
  - [ ] Test result aggregation

### Implementation Hints

```ruby
def run(paths = [])
  # File discovery
  discovery = Herb::Core::FileDiscovery.new(
    base_dir: Dir.pwd,
    include_patterns: config.include_patterns,
    exclude_patterns: config.exclude_patterns
  )
  files = discovery.discover(paths)

  # Get enabled rules (all rules for MVP)
  rule_classes = RuleRegistry.all
  rules = rule_classes.map { |rule_class| rule_class.new }

  # Generate Linter
  linter = Linter.new(rules, config)

  # Process each file
  results = files.map do |file_path|
    source = File.read(file_path)
    linter.lint(file_path: file_path, source: source)
  end

  AggregatedResult.new(results)
end
```

### Verification

```bash
bundle exec rspec spec/herb/lint/runner_spec.rb
```

**Expected result:** All tests pass

---

## Phase 5 Completion Criteria

- [ ] All tasks (5.1–5.4) completed
- [ ] `bundle exec rspec` passes all tests
- [ ] Complete flow from file discovery to lint execution works
- [ ] Verify operation with integration tests

---

## Next Phase

After Phase 5 is complete, proceed to [Phase 6: Reporter & CLI Implementation](./phase-6-reporter-cli.md).
