# Introduce factory_bot to herb-lint

Incrementally introduce factory_bot into herb-lint tests. To minimize conflicts and keep PRs easy to review, replace one factory (one class) at a time.

## Background

Tests currently use `build_offense` / `build_lint_result` helpers defined in `spec_helper.rb`. Several problems have emerged as the test suite has grown:

- Tests specify attributes irrelevant to what they verify (e.g., the `#line` test in `offense_spec.rb` must specify `rule_name`, `message`, and `severity`)
- `build_offense` requires `severity:` with no default, forcing every caller to specify it even when severity is not under test
- Inline `LintResult.new` calls require `file_path:` and `source:` every time, adding noise when only offenses matter
- `directive_parser_spec.rb` redefines `build_offense` locally because the global helper's interface does not fit its needs
- Customizing the end position requires 3 lines of `Position.new` / `Location.new` boilerplate

factory_bot addresses these by providing sensible defaults so each test only specifies the attributes it cares about.

## Prerequisites

- All existing tests pass

---

## Task 1: factory_bot Setup

- [x] Add `factory_bot` and `rspec-factory_bot` to `herb-lint/Gemfile`
- [x] Run `bundle install`
- [x] Create `herb-lint/spec/factories/` directory
- [x] Add factory_bot configuration to `herb-lint/spec/spec_helper.rb`
- [x] Verify all existing tests still pass

**Addition to spec_helper.rb:**

```ruby
require "factory_bot"
require "rspec-factory_bot"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  FactoryBot.find_definitions
end
```

---

## Task 2: Offense Factory

Offense is constructed in the most test files, making it the highest-impact factory. `Herb::Position` and `Herb::Location` are external gem classes but are handled as internal dependencies of the Offense factory via transient attributes.

- [x] Create `herb-lint/spec/factories/offense.rb`
- [x] Replace all `build_offense` calls and inline `Offense.new` with `build(:offense, ...)`
- [x] Remove `build_offense` and `build_location` from `spec_helper.rb`
- [x] Remove any local `build_offense` redefinitions in spec files
- [x] Verify all tests pass

**Factory definition:**

```ruby
# herb-lint/spec/factories/offense.rb
FactoryBot.define do
  factory :offense, class: "Herb::Lint::Offense" do
    rule_name { "test-rule" }
    message { "Test message" }
    severity { "error" }

    transient do
      start_line { 1 }
      start_column { 0 }
      end_line { start_line }
      end_column { start_column }
    end

    location do
      Herb::Location.new(
        Herb::Position.new(start_line, start_column),
        Herb::Position.new(end_line, end_column)
      )
    end

    initialize_with { new(rule_name:, message:, severity:, location:) }
  end
end
```

**Replacement examples:**

```ruby
# Before (offense_spec.rb #line)
let(:offense) do
  described_class.new(
    rule_name: "html-img-require-alt",
    message: "Image missing alt attribute",
    severity: "error",
    location:
  )
end
let(:location) { build_location(line: 42, column: 10) }

# After
let(:offense) { build(:offense, start_line: 42) }
```

```ruby
# Before (directive_parser_spec.rb — local redefinition)
def build_offense(rule_name:, line:)
  location = Herb::Location.new(
    Herb::Position.new(line, 0),
    Herb::Position.new(line, 0)
  )
  Herb::Lint::Offense.new(rule_name:, message: "msg", severity: "error", location:)
end

# After (local definition removed)
build(:offense, rule_name: "rule1", start_line: 1)
```

```ruby
# Before (json_reporter_spec.rb — end position test)
start_pos = Herb::Position.new(12, 5)
end_pos = Herb::Position.new(12, 35)
location = Herb::Location.new(start_pos, end_pos)
Herb::Lint::Offense.new(
  rule_name: "html-img-require-alt",
  message: "Missing alt attribute on img tag",
  severity: "error",
  location:
)

# After
build(:offense, start_line: 12, start_column: 5, end_line: 12, end_column: 35)
```

---

## Task 3: LintResult Factory

LintResult is frequently constructed inline in reporter specs, where `file_path:` and `source:` are always noise.

- [x] Create `herb-lint/spec/factories/lint_result.rb`
- [x] Replace all `build_lint_result` calls and inline `LintResult.new` with `build(:lint_result, ...)`
- [x] Remove `build_lint_result` from `spec_helper.rb` (remove `TestHelpers` module if empty)
- [x] Verify all tests pass

**Factory definition:**

```ruby
# herb-lint/spec/factories/lint_result.rb
FactoryBot.define do
  factory :lint_result, class: "Herb::Lint::LintResult" do
    file_path { "test.html.erb" }
    offenses { [] }
    source { "<div></div>" }

    initialize_with { new(file_path:, offenses:, source:) }

    trait :with_errors do
      transient do
        error_count { 1 }
      end

      offenses do
        Array.new(error_count) { build(:offense, severity: "error") }
      end
    end

    trait :with_warnings do
      transient do
        warning_count { 1 }
      end

      offenses do
        Array.new(warning_count) { build(:offense, severity: "warning") }
      end
    end
  end
end
```

**Replacement examples:**

```ruby
# Before (aggregated_result_spec.rb)
build_lint_result(errors: 2, warnings: 1)

# After
build(:lint_result, :with_errors, :with_warnings, error_count: 2, warning_count: 1)
```

```ruby
# Before (json_reporter_spec.rb)
Herb::Lint::LintResult.new(
  file_path: "app/views/users/index.html.erb",
  offenses: [],
  source: "<div></div>"
)

# After
build(:lint_result, file_path: "app/views/users/index.html.erb")
```

```ruby
# Before (simple_reporter_spec.rb)
Herb::Lint::LintResult.new(
  file_path: "test.html.erb",
  offenses: [
    build_offense(severity: "warning", rule_name: "test-rule", message: "Warning message", line: 1, column: 0)
  ],
  source: "<div></div>"
)

# After
build(:lint_result, offenses: [
  build(:offense, severity: "warning", rule_name: "test-rule", message: "Warning message", start_line: 1)
])
```

---

## Task 4: Update CLAUDE.md with factory_bot Guidelines

Add a brief note about factory_bot to CLAUDE.md under "Testing Policy".

- [ ] Note that herb-lint uses factory_bot for test object creation
- [ ] List the available factories with a pointer to the definitions directory (`herb-lint/spec/factories/`)

**Content to add to CLAUDE.md (under Testing Policy):**

~~~markdown
### factory_bot

herb-lint uses [factory_bot](https://github.com/thoughtbot/factory_bot) for test object creation. Factories are defined in `herb-lint/spec/factories/`.

Available factories: `:offense`, `:lint_result`
~~~

---

## Summary

| Task | Description |
|------|-------------|
| Task 1 | factory_bot setup |
| Task 2 | Offense factory |
| Task 3 | LintResult factory |
| Task 4 | Update CLAUDE.md with factory_bot guidelines |
